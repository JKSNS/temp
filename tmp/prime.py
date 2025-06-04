import os
import torch
import torch.nn.functional as F
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    AutoModelForCausalLM,
    AutoModelForSeq2SeqLM,
)
from sklearn.metrics import auc, roc_curve

# -----------------------------
# 1. CONFIGURE DEVICE & PATHS
# -----------------------------
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Adjust these paths to wherever the models live on-premises
RADAR_DETECTOR_PATH          = "/local/models/RADAR-Vicuna-7B"
VICUNA_GENERATOR_PATH       = "/local/models/vicuna_7b_v1.5"
T5_PARAPHRASER_PATH         = "/local/models/chatgpt_paraphraser_on_T5_base"

# -----------------------------
# 2. LOAD RADAR DETECTOR
# -----------------------------
# (This is the RoBERTa‐large model fine‐tuned for AI‐text detection)
detector_tokenizer = AutoTokenizer.from_pretrained(RADAR_DETECTOR_PATH)
detector = AutoModelForSequenceClassification.from_pretrained(RADAR_DETECTOR_PATH)
detector.eval().to(device)

# -----------------------------
# 3. LOAD VICUNA GENERATOR
# -----------------------------
# (This is the on-premises Vicuna 7B model used to produce AI‐text samples)
generator_tokenizer = AutoTokenizer.from_pretrained(VICUNA_GENERATOR_PATH)
generator = AutoModelForCausalLM.from_pretrained(VICUNA_GENERATOR_PATH)
generator.eval().to(device)

# Ensure padding token is set for generation
generator_tokenizer.pad_token = generator_tokenizer.eos_token
generator_tokenizer.padding_side = "left"
generator_tokenizer.truncation_side = "right"

# -----------------------------
# 4. LOAD T5 PARAPHRASER
# -----------------------------
# (This is a T5‐based paraphraser downloaded locally)
paraphraser_tokenizer = AutoTokenizer.from_pretrained(T5_PARAPHRASER_PATH)
paraphraser = AutoModelForSeq2SeqLM.from_pretrained(T5_PARAPHRASER_PATH)
paraphraser.eval().to(device)

# -----------------------------
# 5. GENERATE AI-TEXT SAMPLES
# -----------------------------
# Example “human prompts” (replace with your own corpus as needed)
human_prompts = [
    "Maj Richard Scott, 40, is accused of driving at speeds of up to 95mph (153km/h) in bad weather before the smash on a B-road in Wiltshire...",
    "Solar concentrating technologies such as parabolic dish, trough and Scheffler reflectors can provide process heat for commercial and industrial applications...",
    "The Bush administration then turned its attention to Iraq, and argued the need to remove Saddam Hussein from power in Iraq had become urgent..."
]

instruction = "You are a helpful assistant. Complete the given text:"

# Tokenize the prefix (instruction + human text)
prefix_inputs = generator_tokenizer(
    [f"{instruction} {sent}" for sent in human_prompts],
    max_length=30,
    padding="max_length",
    truncation=True,
    return_tensors="pt"
)
prefix_inputs = {k: v.to(device) for k, v in prefix_inputs.items()}

# Generate AI-text completions
with torch.no_grad():
    outputs = generator.generate(
        **prefix_inputs,
        max_new_tokens=512,
        do_sample=True,
        temperature=0.6,
        top_p=0.9,
        pad_token_id=generator_tokenizer.pad_token_id
    )

decoded = generator_tokenizer.batch_decode(outputs, skip_special_tokens=True)
ai_texts = [
    text.replace(f"{instruction} ", "")
    for text in decoded
]

print("=== AI-generated samples ===")
for i, txt in enumerate(ai_texts, 1):
    snippet = txt[:200].replace("\n", " ")
    print(f"{i}. {snippet}...\n")

# -----------------------------
# 6. PARAPHRASE AI-TEXT (T5-BASED)
# -----------------------------
def t5_paraphrase(text: str) -> str:
    """
    Paraphrase 'text' using an on-premises T5 paraphraser.
    """
    input_ids = paraphraser_tokenizer(
        f"paraphrase: {text}",
        return_tensors="pt",
        padding="longest",
        truncation=True,
        max_length=512
    ).input_ids.to(device)

    with torch.no_grad():
        outputs = paraphraser.generate(
            input_ids,
            temperature=0.7,
            repetition_penalty=10.0,
            num_beams=5,
            num_beam_groups=5,
            num_return_sequences=1,
            no_repeat_ngram_size=2,
            diversity_penalty=3.0,
            max_length=512
        )
    paraphrased = paraphraser_tokenizer.batch_decode(outputs, skip_special_tokens=True)
    return paraphrased[0]

paraphrased_ai_texts = [t5_paraphrase(txt) for txt in ai_texts]

print("\n=== Paraphrased AI samples ===")
for i, txt in enumerate(paraphrased_ai_texts, 1):
    snippet = txt[:200].replace("\n", " ")
    print(f"{i}. {snippet}...\n")

# -----------------------------
# 7. SCORING / DETECTION
# -----------------------------
def get_ai_prob_list(texts: list[str]) -> list[float]:
    """
    Returns a list of P(AI) scores for each text in 'texts' using RADAR.
    """
    with torch.no_grad():
        enc = detector_tokenizer(
            texts,
            padding=True,
            truncation=True,
            max_length=512,
            return_tensors="pt"
        )
        enc = {k: v.to(device) for k, v in enc.items()}
        logits = detector(**enc).logits
        probs = F.softmax(logits, dim=-1)[:, 0].tolist()
    return probs

# Score human prompts (expected low P(AI))
human_preds = get_ai_prob_list(human_prompts)
print("Human prompts → P(AI) :", human_preds)

# Score raw AI-generated texts (expected high P(AI))
ai_preds = get_ai_prob_list(ai_texts)
print("AI-generated texts → P(AI) :", ai_preds)

# Score paraphrased AI texts (should remain relatively high)
paraphrased_preds = get_ai_prob_list(paraphrased_ai_texts)
print("Paraphrased AI texts → P(AI) :", paraphrased_preds)

# -----------------------------
# 8. COMPUTE DETECTION AUROC
# -----------------------------
def get_roc_metrics(human_probs: list[float], ai_probs: list[float]):
    """
    Given lists of “human_probs” (label=0) and “ai_probs” (label=1),
    compute FPR, TPR, and AUROC.
    """
    labels = [0] * len(human_probs) + [1] * len(ai_probs)
    scores = human_probs + ai_probs
    fpr, tpr, _ = roc_curve(labels, scores, pos_label=1)
    roc_auc = auc(fpr, tpr)
    return fpr.tolist(), tpr.tolist(), float(roc_auc)

fpr_no_para, tpr_no_para, auc_no_para = get_roc_metrics(human_preds, ai_preds)
fpr_para,    tpr_para,    auc_para    = get_roc_metrics(human_preds, paraphrased_preds)

print(f"\nW/O Paraphrase → AUROC = {auc_no_para:.4f}")
print(f"W/ Paraphrase → AUROC = {auc_para:.4f}")

# -----------------------------
# 9. SUMMARY
# -----------------------------
# This script:
#  1. Loads all models from local directories (no Hugging Face downloads).
#  2. Generates AI-text via Vicuna 7B.
#  3. Paraphrases those AI-texts with an on-premises T5 model.
#  4. Scores human, AI, and paraphrased AI with the RADAR detector.
#  5. Computes AUROC before/after paraphrasing.
# Adjust the paths at the top to point to your on-prem model directories.
# Ensure your conda environment (radar_core.yaml + requirements.txt) has compatible
# versions of torch, transformers, and scikit-learn installed.