Here’s how you can run all of RADAR’s pieces entirely on-prem, pointing at locally stored model checkpoints instead of pulling from the Hugging Face Hub.

---

## 1. Prepare your local model directories

1. **Clone the RADAR repo**

   ```bash
   git clone https://github.com/IBM/RADAR.git
   cd RADAR
   ```

2. **Download each HF model to disk**
   You have two main detectors (e.g. RADAR-Vicuna-7B) and two paraphrasers (OpenAI API and T5-based). Choose one or both:

   ```bash
   # via huggingface_hub snapshot_download (you’ll need huggingface_hub installed)
   python - <<EOF
   from huggingface_hub import snapshot_download
   snapshot_download("TrustSafeAI/RADAR-Vicuna-7B",     local_dir="models/RADAR-Vicuna-7B")
   snapshot_download("humarin/chatgpt_paraphraser_on_T5_base", local_dir="models/T5-paraphraser")
   # ...and any generator models you need, e.g. Vicuna checkpoints:
   snapshot_download("meta-llama/Llama-2-7b-chat-hf",   local_dir="models/Vicuna-7B")
   EOF
   ```

   Or, if you already have checkpoint folders (e.g. from a private registry), just place them under `models/…`.

---

## 2. Modify your code to load locally

Where you previously had:

```python
detector = AutoModelForSequenceClassification.from_pretrained("TrustSafeAI/RADAR-Vicuna-7B")
```

change to:

```python
detector = AutoModelForSequenceClassification.from_pretrained(
    "/full/path/to/RADAR/models/RADAR-Vicuna-7B",
    local_files_only=True
)
tokenizer = AutoTokenizer.from_pretrained(
    "/full/path/to/RADAR/models/RADAR-Vicuna-7B",
    local_files_only=True
)
```

Do the same for your generator and paraphraser:

```python
generator = AutoModelForCausalLM.from_pretrained(
    "/full/path/to/models/Vicuna-7B",
    local_files_only=True
)
gen_tokenizer = AutoTokenizer.from_pretrained(
    "/full/path/to/models/Vicuna-7B",
    local_files_only=True
)

# T5-based paraphraser:
paraphraser = AutoModelForSeq2SeqLM.from_pretrained(
    "/full/path/to/models/T5-paraphraser",
    local_files_only=True
)
para_tokenizer = AutoTokenizer.from_pretrained(
    "/full/path/to/models/T5-paraphraser",
    local_files_only=True
)
```

---

## 3. Force offline mode (optional but recommended)

Set environment vars so that 🤗 Transformers never tries to go online:

```bash
export TRANSFORMERS_OFFLINE=1
export HF_DATASETS_OFFLINE=1
export HF_METRICS_OFFLINE=1
```

---

## 4. Run detection, generation & paraphrasing exactly as in the examples

All of the RADAR example code (in `radar_examples.ipynb` or your scripts) stays the same—just point `from_pretrained()` at your local folders and it will:

* **Detect** on human / AI / paraphrased-AI text
* **Generate** AI completions via Vicuna (or any other local LLM)
* **Paraphrase** via local T5 model

---

## 5. Evaluating performance

You already have the AUROC snippet:

```python
fpr, tpr, auc_score = get_roc_metrics(human_probs, ai_probs)
print("AUROC:", auc_score)
```

No change here.

---

## 6. Folder layout suggestion

```
RADAR/
├── env/                     # your conda-env files
├── radar_requirements.txt
├── radar_core.yaml
├── radar_examples.ipynb
└── models/
    ├── RADAR-Vicuna-7B/     # detector
    ├── Vicuna-7B/           # generator
    └── T5-paraphraser/      # optional paraphraser
```

---

### Recap

1. **Snapshot** your Hugging Face repos locally (or place your own checkpoints under `models/`).
2. **Load** with `from_pretrained("/path/to/models/…", local_files_only=True)`.
3. **Set** `TRANSFORMERS_OFFLINE=1` if you want strict no-internet.
4. **Run** detection, generation, paraphrasing and AUROC exactly as in the RADAR examples—nothing else changes.

That way, everything runs fully on-prem, using only your downloaded model files.
