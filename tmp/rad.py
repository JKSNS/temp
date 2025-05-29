#!/usr/bin/env python3
"""
run_radar.py

A standalone script to:
  1. Load the RADAR detector and tokenizer
  2. Generate AI-text completions via a Vicuna model
  3. Paraphrase AI-text via OpenAI GPT
  4. Run detection on human, AI, and paraphrased texts
  5. Compute and print AUROC metrics

Usage:
  python3 -m venv venv
  source venv/bin/activate
  pip install -r radar_requirements.txt
  python run_radar.py
"""

import transformers
import torch
import torch.nn.functional as F
from sklearn.metrics import auc, roc_curve
import openai

# Configuration
DEVICE = "cuda:6"  # adjust as needed, e.g. "cuda:0" or "cpu"
DETECTOR_ID = "TrustSafeAI/RADAR-Vicuna-7B"
GENERATOR_ID = "/research/d1/gds/xmhu23/checkpoints/vicuna_7b_v1.5"
OPENAI_MODEL = "gpt-3.5-turbo"
openai.api_key = "your_api_key_here"

# Sample human texts
HUMAN_TEXTS = [
    """Maj Richard Scott, 40, is accused of driving at speeds of up to 95mph (153km/h) in bad weather before the smash on a B-road in Wiltshire. Gareth Hicks, 24, suffered fatal injuries when the van he was asleep in was hit by Mr Scott's Audi A6. Maj Scott denies a charge of causing death by careless driving. Prosecutor Charles Gabb alleged the defendant, from Green Lane in Shepperton, Surrey, had crossed the carriageway of the 60mph-limit B390 in Shrewton near Amesbury. The weather was "awful" and there was strong wind and rain, he told jurors. He said Mr Scott's car was described as "twitching" and "may have been aquaplaning" before striking the first vehicle; a BMW driven by Craig Reed. Mr Scott's Audi then returned to his side of the road but crossed the carriageway again before colliding""",
    """Solar concentrating technologies such as parabolic dish, trough and Scheffler reflectors can provide process heat for commercial and industrial applications. The first commercial system was the Solar Total Energy Project (STEP) in Shenandoah, Georgia, USA where a field of 114 parabolic dishes provided 50% of the process heating, air conditioning and electrical requirements for a clothing factory. This grid-connected cogeneration system provided 400 kW of electricity plus thermal energy in the form of 401 kW steam and 468 kW chilled water, and had a one-hour peak load thermal storage. Evaporation ponds are shallow pools that concentrate dissolved solids through evaporation. The use of evaporation ponds to obtain salt from sea water is one of the oldest applications of solar energy. Modern uses include concentrating brine solutions used in leach mining and removing dissolved solids from waste""",
    """The Bush administration then turned its attention to Iraq, and argued the need to remove Saddam Hussein from power in Iraq had become urgent. Among the stated reasons were that Saddam's regime had tried to acquire nuclear material and had not properly accounted for biological and chemical material it was known to have previously possessed, and believed to still maintain. Both the possession of these weapons of mass destruction (WMD), and the failure to account for them, would violate the U.N. sanctions. The assertion about WMD was hotly advanced by the Bush administration from the beginning, but other major powers including China, France, Germany, and Russia remained unconvinced that Iraq was a threat and refused to allow passage of a UN Security Council resolution to authorize the use of force. Iraq permitted UN weapon inspectors in November 2002, who were continuing their work to assess the WMD claim when the Bush administration decided to proceed with war without UN authorization and told the inspectors to leave the""",
]

INSTRUCTION = "You are helpful assistant to complete given text:"


def load_detector(detector_id, device):
    detector = transformers.AutoModelForSequenceClassification.from_pretrained(detector_id)
    tokenizer = transformers.AutoTokenizer.from_pretrained(detector_id)
    detector.eval()
    detector.to(device)
    return detector, tokenizer


def detect(texts, detector, tokenizer, device):
    """Return list of probabilities that each text is AI-generated."""
    with torch.no_grad():
        inputs = tokenizer(texts, padding=True, truncation=True, max_length=512, return_tensors="pt")
        inputs = {k: v.to(device) for k, v in inputs.items()}
        logits = detector(**inputs).logits
        probs = F.log_softmax(logits, dim=-1)[:, 0].exp().tolist()
    return probs


def load_generator(generator_id, device):
    gen = transformers.AutoModelForCausalLM.from_pretrained(generator_id)
    gen_tokenizer = transformers.AutoTokenizer.from_pretrained(generator_id)
    gen.eval()
    gen.to(device)
    return gen, gen_tokenizer


def generate_ai_texts(generator, gen_tokenizer, human_texts, instruction, device):
    gen_tokenizer.pad_token = gen_tokenizer.eos_token
    gen_tokenizer.padding_side = 'left'
    gen_tokenizer.truncation_side = 'right'
    prompt_inputs = gen_tokenizer(
        [f"{instruction} {h}" for h in human_texts],
        max_length=30, padding='max_length', truncation=True, return_tensors="pt"
    )
    prompt_inputs = {k: v.to(device) for k, v in prompt_inputs.items()}
    outputs = generator.generate(
        **prompt_inputs,
        max_new_tokens=512,
        do_sample=True,
        temperature=0.6,
        top_p=0.9,
        pad_token_id=gen_tokenizer.pad_token_id
    )
    decoded = gen_tokenizer.batch_decode(outputs, skip_special_tokens=True)
    return [t.replace(f"{instruction} ", "") for t in decoded]


def paraphrase_openai(texts, model):
    """Use OpenAI API to paraphrase each text."""
    paraphrased = []
    for t in texts:
        r = openai.ChatCompletion.create(
            model=model,
            messages=[
                {"role": "system", "content": "Enhance the word choices in the sentence to sound more like that of a human."},
                {"role": "user", "content": t}
            ]
        )['choices'][0].message.content
        paraphrased.append(r)
    return paraphrased


def get_roc_metrics(human_preds, ai_preds):
    """Compute FPR, TPR, and AUROC."""
    fpr, tpr, _ = roc_curve([0] * len(human_preds) + [1] * len(ai_preds), human_preds + ai_preds, pos_label=1)
    return fpr.tolist(), tpr.tolist(), float(auc(fpr, tpr))


def main():
    # 1) Load detector
    detector, tokenizer = load_detector(DETECTOR_ID, DEVICE)

    # 2) Load generator & produce AI-texts
    generator, gen_tokenizer = load_generator(GENERATOR_ID, DEVICE)
    ai_texts = generate_ai_texts(generator, gen_tokenizer, HUMAN_TEXTS, INSTRUCTION, DEVICE)

    # 3) Paraphrase AI-texts
    paraphrased = paraphrase_openai(ai_texts, OPENAI_MODEL)

    # 4) Run detection
    human_preds = detect(HUMAN_TEXTS, detector, tokenizer, DEVICE)
    ai_preds = detect(ai_texts, detector, tokenizer, DEVICE)
    para_preds = detect(paraphrased, detector, tokenizer, DEVICE)

    # 5) Compute AUROC
    fpr1, tpr1, auc1 = get_roc_metrics(human_preds, ai_preds)
    fpr2, tpr2, auc2 = get_roc_metrics(human_preds, para_preds)

    print(f"W/O Paraphrase Detection AUROC: {auc1:.4f}")
    print(f"W/ Paraphrase Detection AUROC: {auc2:.4f}")


if __name__ == "__main__":
    main()
