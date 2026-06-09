"""
Infant Cry Classification — FastAPI Service
============================================
Mirrors the exact inference pipeline from Cell 10 of the notebook.

Endpoints
---------
GET  /health          → liveness check + model info
GET  /classes         → list of supported class labels
POST /predict         → classify a single audio file
POST /predict/batch   → classify multiple audio files
GET  /predict/file    → classify by server-side file path (for Kaggle testing)
"""

import os
import io
import math
import time
import tempfile
import logging
from collections import Counter
from contextlib import asynccontextmanager
from typing import Optional

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchaudio
import torchaudio.functional as AF

from fastapi import FastAPI, File, UploadFile, HTTPException, Query
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.model import build_model, load_checkpoint
from app.preprocessing import preprocess_audio_bytes, preprocess_audio_path
from app.inference import run_inference

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s | %(levelname)s | %(message)s")
log = logging.getLogger(__name__)

# ── Global model state (loaded once at startup) ───────────────────────────────
MODEL_STATE: dict = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load model on startup, release on shutdown."""
    log.info("Loading model...")
    t0 = time.time()

    checkpoint_path = os.environ.get("CHECKPOINT_PATH", "models/best_w2v_ecapa.pt")
    device_str      = os.environ.get("DEVICE", "cuda" if torch.cuda.is_available() else "cpu")
    device          = torch.device(device_str)

    model, aam_head = build_model(device)

    if os.path.exists(checkpoint_path):
        load_checkpoint(checkpoint_path, model, aam_head, device)
        log.info(f"Checkpoint loaded from: {checkpoint_path}")
    else:
        log.warning(f"No checkpoint at {checkpoint_path} — model is random weights!")

    model.eval()
    aam_head.eval()

    MODEL_STATE["model"]    = model
    MODEL_STATE["aam_head"] = aam_head
    MODEL_STATE["device"]   = device

    log.info(f"Model ready in {time.time()-t0:.2f}s on {device}")
    yield

    MODEL_STATE.clear()
    log.info("Model released.")


# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Infant Cry Classifier",
    description="wav2vec2-Base → AttentionMerge → ECAPA-TDNN → ArcFace (4-class)",
    version="1.0.0",
    lifespan=lifespan,
)


# ── Response schemas ──────────────────────────────────────────────────────────
class Segment(BaseModel):
    start_sec:  float
    end_sec:    float
    label:      str
    confidence: float
    n_windows:  int
    all_probs:  dict[str, float]


class PredictResponse(BaseModel):
    filename:       str
    duration_sec:   float
    raw_sr:         int
    n_segments:     int
    segments:       list[Segment]
    processing_ms:  float


class HealthResponse(BaseModel):
    status:      str
    device:      str
    checkpoint:  str
    classes:     list[str]


class ClassesResponse(BaseModel):
    classes:     list[str]
    n_classes:   int


# ── Constants (must match notebook Cell 2) ────────────────────────────────────
CLASSES = ["scared", "needs", "physical_pain", "burping"]
SUPPORTED_EXTS = {".wav", ".mp3", ".ogg", ".m4a", ".flac", ".opus", ".aac"}


# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/health", response_model=HealthResponse, tags=["System"])
def health():
    ckpt = os.environ.get("CHECKPOINT_PATH", "checkpoints/best_w2v_ecapa.pt")
    return HealthResponse(
        status     = "ok" if MODEL_STATE else "not_loaded",
        device     = str(MODEL_STATE.get("device", "unknown")),
        checkpoint = ckpt,
        classes    = CLASSES,
    )


@app.get("/classes", response_model=ClassesResponse, tags=["System"])
def classes():
    return ClassesResponse(classes=CLASSES, n_classes=len(CLASSES))


@app.post("/predict", response_model=PredictResponse, tags=["Inference"])
async def predict(file: UploadFile = File(...)):
    """
    Upload a single audio file (wav, mp3, ogg, m4a, flac, opus, aac).
    Returns per-segment classification with timestamps, confidence, and
    full probability distribution over all 4 classes.
    """
    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in SUPPORTED_EXTS:
        raise HTTPException(400, f"Unsupported format '{ext}'. Supported: {SUPPORTED_EXTS}")

    audio_bytes = await file.read()
    if len(audio_bytes) == 0:
        raise HTTPException(400, "Empty file.")

    t0 = time.time()
    try:
        result = run_inference(
            audio_source   = audio_bytes,
            source_type    = "bytes",
            model          = MODEL_STATE["model"],
            aam_head       = MODEL_STATE["aam_head"],
            device         = MODEL_STATE["device"],
            filename       = file.filename or "upload",
        )
    except Exception as e:
        log.exception("Inference error")
        raise HTTPException(500, f"Inference failed: {e}")

    result["processing_ms"] = round((time.time() - t0) * 1000, 1)
    return PredictResponse(**result)


@app.post("/predict/batch", tags=["Inference"])
async def predict_batch(files: list[UploadFile] = File(...)):
    """
    Upload multiple audio files. Returns a list of PredictResponse objects.
    Files are processed sequentially (GPU memory safety).
    """
    if len(files) > 20:
        raise HTTPException(400, "Maximum 20 files per batch request.")

    responses = []
    for file in files:
        ext = os.path.splitext(file.filename or "")[1].lower()
        if ext not in SUPPORTED_EXTS:
            responses.append({"filename": file.filename, "error": f"Unsupported format '{ext}'"})
            continue

        audio_bytes = await file.read()
        t0 = time.time()
        try:
            result = run_inference(
                audio_source = audio_bytes,
                source_type  = "bytes",
                model        = MODEL_STATE["model"],
                aam_head     = MODEL_STATE["aam_head"],
                device       = MODEL_STATE["device"],
                filename     = file.filename or "upload",
            )
            result["processing_ms"] = round((time.time() - t0) * 1000, 1)
            responses.append(result)
        except Exception as e:
            log.exception(f"Inference error on {file.filename}")
            responses.append({"filename": file.filename, "error": str(e)})

    return JSONResponse(content=responses)


@app.get("/predict/file", response_model=PredictResponse, tags=["Inference"])
def predict_file(
    path: str = Query(..., description="Server-side absolute path to audio file"),
):
    """
    Classify a file already on the server (e.g. Kaggle input directory).
    Useful for testing without file upload.
    Example: /predict/file?path=/kaggle/input/test-audio/cry1.wav
    """
    if not os.path.exists(path):
        raise HTTPException(404, f"File not found: {path}")

    ext = os.path.splitext(path)[1].lower()
    if ext not in SUPPORTED_EXTS:
        raise HTTPException(400, f"Unsupported format '{ext}'.")

    t0 = time.time()
    try:
        result = run_inference(
            audio_source = path,
            source_type  = "path",
            model        = MODEL_STATE["model"],
            aam_head     = MODEL_STATE["aam_head"],
            device       = MODEL_STATE["device"],
            filename     = os.path.basename(path),
        )
    except Exception as e:
        log.exception("Inference error")
        raise HTTPException(500, f"Inference failed: {e}")

    result["processing_ms"] = round((time.time() - t0) * 1000, 1)
    return PredictResponse(**result)
