"""
inference.py
------------
Sliding-window inference with VAD segmentation and majority vote.
Mirrors infer_file_summary() and classify_segment() from Cell 10 exactly.
Adds full probability distribution per segment (not in original notebook).
"""

from collections import Counter
from typing import Union

import numpy as np
import torch
import torch.nn.functional as F
import torchaudio

from app.preprocessing import (
    preprocess_audio_bytes,
    preprocess_audio_path,
    energy_vad,
    SR,
    TARGET_SAMPLES,
)

CLASSES = ["scared", "needs", "physical_pain", "burping"]


@torch.no_grad()
def classify_chunk(chunk: np.ndarray, model, aam_head,
                   device: torch.device) -> tuple[str, float, dict[str, float]]:
    """
    Classify one audio chunk.
    Returns (label, confidence, {class: prob}) — exact logic from Cell 10,
    plus full probability dict for richer API responses.
    """
    # Pad or truncate to TARGET_SAMPLES
    if len(chunk) >= TARGET_SAMPLES:
        chunk = chunk[:TARGET_SAMPLES]
    else:
        chunk = np.pad(chunk, (0, TARGET_SAMPLES - len(chunk)))

    x = torch.from_numpy(chunk).unsqueeze(0).to(device)
    x = (x - x.mean()) / (x.std() + 1e-8)             # z-score — matches training

    with torch.autocast(device_type=device.type,
                        enabled=(device.type == "cuda")):
        emb    = model(x)                               # [1, 512]
        logits = aam_head.get_logits(emb.float()).squeeze(0)  # [4]

    probs = torch.softmax(logits, dim=0).cpu().numpy()
    idx   = int(np.argmax(probs))
    label = CLASSES[idx]
    conf  = float(probs[idx])
    all_probs = {c: round(float(p), 4) for c, p in zip(CLASSES, probs)}

    return label, conf, all_probs


def run_inference(
    audio_source: Union[bytes, str],
    source_type:  str,           # "bytes" | "path"
    model,
    aam_head,
    device:       torch.device,
    filename:     str = "audio",
) -> dict:
    """
    Full inference pipeline:
      1. Preprocess (HPF → VAD-trim → LUFS → peak norm)
      2. VAD-segment into cry episodes
      3. Sliding-window classify each episode (1-second stride)
      4. Majority vote per episode
      5. Return structured result dict

    Mirrors infer_file_summary() from Cell 10.
    """
    model.eval()
    aam_head.eval()

    # ── 1. Load + preprocess ──────────────────────────────────────────────────
    if source_type == "bytes":
        wav_np, raw_sr, raw_n = preprocess_audio_bytes(audio_source)
    elif source_type == "path":
        wav_np, raw_sr, raw_n = preprocess_audio_path(audio_source)
    else:
        raise ValueError(f"Unknown source_type: {source_type}")

    duration_sec = raw_n / raw_sr

    # ── 2. VAD segmentation ───────────────────────────────────────────────────
    segs = energy_vad(wav_np, SR)

    # ── 3+4. Classify each segment ────────────────────────────────────────────
    segments_out = []

    for seg_start, seg_end in segs:
        seg_wav = wav_np[seg_start:seg_end]
        seg_t0  = seg_start / SR
        seg_t1  = seg_end   / SR

        votes         = []   # list of (label, conf, all_probs)
        offset        = 0
        min_chunk_len = int(0.4 * TARGET_SAMPLES)  # 40% of clip = valid window

        while offset < len(seg_wav):
            chunk = seg_wav[offset : offset + TARGET_SAMPLES]
            if len(chunk) >= min_chunk_len:
                label, conf, all_probs = classify_chunk(chunk, model, aam_head, device)
                votes.append((label, conf, all_probs))
            offset += SR   # 1-second stride

        if not votes:
            continue

        # Majority vote on label
        winner = Counter(v[0] for v in votes).most_common(1)[0][0]

        # Average confidence and probs over winning-label windows only
        win_votes = [v for v in votes if v[0] == winner]
        avg_conf  = sum(v[1] for v in win_votes) / len(win_votes)

        # Average full probability distribution over ALL windows (not just winner)
        # Gives a smoother picture of model uncertainty across the segment
        avg_all_probs = {}
        for cls in CLASSES:
            avg_all_probs[cls] = round(
                sum(v[2][cls] for v in votes) / len(votes), 4
            )

        segments_out.append({
            "start_sec":  round(seg_t0, 3),
            "end_sec":    round(seg_t1, 3),
            "label":      winner,
            "confidence": round(avg_conf, 4),
            "n_windows":  len(votes),
            "all_probs":  avg_all_probs,
        })

    return {
        "filename":     filename,
        "duration_sec": round(duration_sec, 3),
        "raw_sr":       raw_sr,
        "n_segments":   len(segments_out),
        "segments":     segments_out,
    }
