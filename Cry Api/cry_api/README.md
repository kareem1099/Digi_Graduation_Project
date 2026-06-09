# Infant Cry Classifier API

A FastAPI-based service for classifying infant cry sounds into 4 categories: scared, needs, physical pain, and burping.

**Architecture**: Wav2Vec2-Base → AttentionMerge → ECAPA-TDNN → ArcFace

---

## 📁 Project Structure

```
cry_api/
├── app/
│   ├── __init__.py              # Package init
│   ├── main.py                  # FastAPI app & endpoints
│   ├── model.py                 # Model architecture (ECAPA-TDNN + Wav2Vec2)
│   ├── inference.py             # Inference pipeline with VAD segmentation
│   └── preprocessing.py         # Audio preprocessing (HPF, VAD, normalization)
├── data/
│   └── test/                    # 👈 Place test audio files here
├── models/
│   └── best_w2v_ecapa.pt        # 👈 Model weights go here (not included)
├── run.py                       # Server entry point
├── test_api.py                  # Simple test script
├── requirements.txt             # Python dependencies
└── README.md                    # This file
└── README.md
```

---

## Quickstart

### Local
```bash
pip install -r requirements.txt

CHECKPOINT_PATH=/path/to/best_w2v_ecapa.pt \
DEVICE=cuda \
python run.py --port 8000
```

### Kaggle (Cell 11)
Paste `cell_11_notebook.py` content into a new notebook cell.  
Update `WHATSAPP_DIR` to your test audio dataset path.

---

## Endpoints

| Method | Path             | Description                              |
|--------|------------------|------------------------------------------|
| GET    | `/health`        | Liveness + model info                    |
| GET    | `/classes`       | List of 4 class labels                   |
| POST   | `/predict`       | Upload single audio file                 |
| POST   | `/predict/batch` | Upload up to 20 files                    |
| GET    | `/predict/file`  | Classify by server-side path (no upload) |

Interactive docs: `http://localhost:8000/docs`

---

## Environment Variables

| Variable          | Default                                   | Description              |
|-------------------|-------------------------------------------|--------------------------|
| `CHECKPOINT_PATH` | `checkpoints/best_w2v_ecapa.pt`           | Path to `.pt` checkpoint |
| `DEVICE`          | `cuda` if available, else `cpu`           | Inference device         |

---

## Example Response

```json
{
  "filename": "whatsapp_audio_001.ogg",
  "duration_sec": 12.4,
  "raw_sr": 16000,
  "n_segments": 2,
  "processing_ms": 843.2,
  "segments": [
    {
      "start_sec": 0.3,
      "end_sec": 5.1,
      "label": "physical_pain",
      "confidence": 0.7821,
      "n_windows": 5,
      "all_probs": {
        "scared": 0.0312,
        "needs": 0.1204,
        "physical_pain": 0.7821,
        "burping": 0.0663
      }
    },
    {
      "start_sec": 7.0,
      "end_sec": 11.8,
      "label": "needs",
      "confidence": 0.8934,
      "n_windows": 4,
      "all_probs": {
        "scared": 0.0102,
        "needs": 0.8934,
        "physical_pain": 0.0714,
        "burping": 0.025
      }
    }
  ]
}
```

---

## Preprocessing Pipeline

Matches dataset README exactly:
1. Load + resample to 16 kHz  
2. Convert to mono  
3. **High-pass filter at 50 Hz** (FIR windowed-sinc)  
4. **VAD-trim** leading/trailing silence  
5. Loudness normalize to −23 LUFS  
6. Peak normalize to [−1, 1]  
7. z-score normalize per chunk at inference time  

---

## Notes

- Keep `--workers 1` — each worker loads the full model (~400MB)
- `GET /predict/file` is faster on Kaggle than POST upload (no I/O overhead)
- `all_probs` in each segment is averaged over all sliding windows in that segment
- `confidence` is averaged only over windows that voted for the winning label
