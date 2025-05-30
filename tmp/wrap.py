#!/usr/bin/env python3
"""
run_radar_local.py

End-to-end RADAR pipeline fully on-prem:
 - Load detector, generator, paraphraser from local directories
 - Generate AI-text completions for human prompts
 - Paraphrase AI-text using local T5 paraphraser
 - Detect AI-generated probabilities
 - Compute AUROC
"""
import os
import torch
import torch.nn.functional as F
from transformers import (
    AutoModelForSequenceClassification, AutoTokenizer,
    AutoModelForCausalLM, AutoModelForSeq2SeqLM
)
from sklearn.metrics import roc_curve, auc

# ================ CONFIGURATION ================
DETECTOR_DIR    = os.path.expanduser("models/RADAR-Vicuna-7B")
GENERATOR_DIR   = os.path.expanduser("models/Vicuna-7B")
PARAPHRASER_DIR = os.path.expanduser("models/T5-paraphraser")
DEVICE          = "cuda:0" if torch.cuda.is_available() else "cpu"

# ================ MODEL LOADERS ================
def load_detector(path, device):
    model = AutoModelForSequenceClassification.from_pretrained(
        path, local_files_only=True
    )
    tokenizer = AutoTokenizer.from_pretrained(
        path, local_files_only=True
    )
    model.eval().to(device)
    return model, tokenizer


def load_generator(path, device):
    model = AutoModelForCausalLM.from_pretrained(
        path, local_files_only=True
    )
    tokenizer = AutoTokenizer.from_pretrained(
        path, local_files_only=True
    )
    model.eval().to(device)
    return model, tokenizer


def load_paraphraser(path, device):
    model = AutoModelForSeq2SeqLM.from_pretrained(
        path, local_files_only=True
    )
    tokenizer = AutoTokenizer.from_pretrained(
        path, local_files_only=True
    )
    model.eval().to(device)
    return model, tokenizer

# ================ CORE FUNCTIONS ================
def detect_probs(texts, model, tokenizer, device, max_length=512):
    inputs = tokenizer(
        texts, padding=True, truncation=True, max_length=max_length,
        return_tensors="pt"
    )
    inputs = {k: v.to(device) for k, v in inputs.items()}
    with torch.no_grad():
        logits = model(**inputs).logits
        probs = F.log_softmax(logits, -1)[:, 0].exp().cpu().tolist()
    return probs


def generate_ai_texts(
    human_texts, model, tokenizer, device,
    instruction="You are a helpful assistant to complete given text:",
    prefix_max_length=30, max_new_tokens=512,
    do_sample=True, temperature=0.6, top_p=0.9
):
    # build prompts
    prompts = [f"{instruction} {t}" for t in human_texts]
    inputs = tokenizer(
        prompts, max_length=prefix_max_length,
        padding="max_length", truncation=True,
        return_tensors="pt"
    )
    inputs = {k: v.to(device) for k, v in inputs.items()}
    outputs = model.generate(
        **inputs,
        max_new_tokens=max_new_tokens,
        do_sample=do_sample,
        temperature=temperature,
        top_p=top_p,
        pad_token_id=tokenizer.eos_token_id
    )
    decoded = tokenizer.batch_decode(outputs, skip_special_tokens=True)
    # strip instruction prefix
    ai_texts = [d.replace(f"{instruction} ", "", 1) for d in decoded]
    return ai_texts


def paraphrase_texts(
    texts, model, tokenizer, device,
    num_beams=5, num_beam_groups=5, num_return_sequences=1,
    repetition_penalty=10.0, diversity_penalty=3.0,
    no_repeat_ngram_size=2, temperature=0.7, max_length=512
):
    paraphrased = []
    for t in texts:
        input_ids = tokenizer(
            f"paraphrase: {t}",
            return_tensors="pt",
            truncation=True, max_length=max_length,
            padding="longest"
        ).input_ids.to(device)
        outputs = model.generate(
            input_ids,
            num_beams=num_beams,
            num_beam_groups=num_beam_groups,
            num_return_sequences=num_return_sequences,
            repetition_penalty=repetition_penalty,
            diversity_penalty=diversity_penalty,
            no_repeat_ngram_size=no_repeat_ngram_size,
            temperature=temperature,
            max_length=max_length
        )
        decoded = tokenizer.batch_decode(outputs, skip_special_tokens=True)
        paraphrased.append(decoded[0])
    return paraphrased


def get_roc_metrics(human_probs, ai_probs):
    labels = [0] * len(human_probs) + [1] * len(ai_probs)
    scores = human_probs + ai_probs
    fpr, tpr, _ = roc_curve(labels, scores, pos_label=1)
    return fpr, tpr, auc(fpr, tpr)

# ================ MAIN PIPELINE ================
def main():
    # Replace these with your actual human text corpus
    human_texts = [
        "First human text sample...",
        "Second human text sample...",
        "Third human text sample..."
    ]

    # Load all models
    detector, det_tok = load_detector(DETECTOR_DIR, DEVICE)
    generator, gen_tok = load_generator(GENERATOR_DIR, DEVICE)
    paraphraser, para_tok = load_paraphraser(PARAPHRASER_DIR, DEVICE)

    # Generate AI and paraphrased texts
    ai_texts      = generate_ai_texts(human_texts, generator, gen_tok, DEVICE)
    para_ai_texts = paraphrase_texts(ai_texts, paraphraser, para_tok, DEVICE)

    # Run detection
    human_probs = detect_probs(human_texts, detector, det_tok, DEVICE)
    ai_probs    = detect_probs(ai_texts, detector, det_tok, DEVICE)
    para_probs  = detect_probs(para_ai_texts, detector, det_tok, DEVICE)

    # Show probabilities
    print("Human probabilities:", human_probs)
    print("AI probabilities:   ", ai_probs)
    print("Paraphrased AI:     ", para_probs)

    # Compute AUROC
    _, _, auc_no_para = get_roc_metrics(human_probs, ai_probs)
    _, _, auc_para    = get_roc_metrics(human_probs, para_probs)
    print(f"AUROC without paraphrase: {auc_no_para:.4f}")
    print(f"AUROC with paraphrase:    {auc_para:.4f}")

if __name__ == "__main__":
    main()
