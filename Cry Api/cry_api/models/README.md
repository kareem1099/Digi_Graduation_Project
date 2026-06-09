# Model Weights

Place your trained model checkpoint here: `best_w2v_ecapa.pt`

**Expected path**: `cry_api/models/best_w2v_ecapa.pt`

The checkpoint should be a PyTorch `.pt` file containing:
- `model`: W2VECAModel state dict
- `aam`: AAMSoftmax head state dict
- `epoch`: (optional) training epoch
- `best_f1`: (optional) best F1 score

## Custom Path

If your model is located elsewhere, specify it before running:

```bash
# Windows
set CHECKPOINT_PATH=C:\path\to\your\model.pt
python run.py

# Linux/Mac
export CHECKPOINT_PATH=/path/to/your/model.pt
python run.py
```

## Default Behavior

If no checkpoint is found, the server will start with **random weights** and log:
```
⚠ No checkpoint at models/best_w2v_ecapa.pt — model is random weights!
```

This is useful for testing the API structure, but predictions will be random.
