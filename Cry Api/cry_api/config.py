"""
config.py
---------
Configuration file for local development.
Adjust these settings for your setup.
"""

import os
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).parent.absolute()
DATA_DIR = PROJECT_ROOT / "data"
TEST_DATA_DIR = DATA_DIR / "test"
MODELS_DIR = PROJECT_ROOT / "models"

# ── Model Configuration ───────────────────────────────────────────────────────
# Default checkpoint path
CHECKPOINT_PATH = os.environ.get(
    "CHECKPOINT_PATH",
    str(MODELS_DIR / "best_w2v_ecapa.pt")
)

# Device (auto-detect if not set)
DEVICE = os.environ.get(
    "DEVICE",
    "cuda" if os.environ.get("DEVICE_FALLBACK", "").lower() == "cuda" else "cpu"
)

# ── Server Configuration ──────────────────────────────────────────────────────
HOST = os.environ.get("HOST", "127.0.0.1")
PORT = int(os.environ.get("PORT", 8000))
RELOAD = os.environ.get("RELOAD", "false").lower() == "true"
WORKERS = int(os.environ.get("WORKERS", 1))  # Keep at 1 for GPU

# ── API Configuration ─────────────────────────────────────────────────────────
MAX_BATCH_SIZE = 20  # Maximum files per /predict/batch request
SUPPORTED_AUDIO_EXTS = {".wav", ".mp3", ".ogg", ".m4a", ".flac", ".opus", ".aac"}

# ── Logging ───────────────────────────────────────────────────────────────────
LOG_LEVEL = "info"  # debug, info, warning, error

# ── Print configuration on import ─────────────────────────────────────────────
if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("Configuration")
    print("=" * 70)
    print(f"Project Root:    {PROJECT_ROOT}")
    print(f"Data Directory:  {DATA_DIR}")
    print(f"Models Directory: {MODELS_DIR}")
    print(f"Checkpoint Path: {CHECKPOINT_PATH}")
    print(f"Device:          {DEVICE}")
    print(f"Server:          {HOST}:{PORT}")
    print(f"Hot Reload:      {RELOAD}")
    print(f"Workers:         {WORKERS}")
    print("=" * 70 + "\n")
