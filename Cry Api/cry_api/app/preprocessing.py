"""
preprocessing.py
----------------
Exact preprocessing pipeline from Cell 10 of the notebook.

Pipeline order (matches dataset README):
  1. Load + resample to 16 kHz
  2. Convert to mono
  3. High-pass filter at 50 Hz
  4. VAD-trim (strip leading/trailing silence)
  5. Loudness normalize to -23 LUFS
  6. Peak normalize to [-1, 1]
"""

import io
import numpy as np
import torch
import torchaudio
import torchaudio.functional as AF

# ── Constants (must match Cell 2) ────────────────────────────────────────────
SR             = 16_000
CLIP_LEN       = 5.0
TARGET_SAMPLES = int(SR * CLIP_LEN)


# ── Step 3: High-pass filter at 50 Hz ────────────────────────────────────────
def highpass_filter_50hz(wav_np: np.ndarray, sr: int = SR) -> np.ndarray:
    """
    Windowed-sinc FIR high-pass at 50 Hz.
    Matches dataset preprocessing — removes low-freq room/handling noise
    that wav2vec2 was never trained to see as cry features.
    """
    nyq    = sr / 2.0
    cutoff = 50.0 / nyq
    n_taps = 101
    half   = n_taps // 2
    n      = np.arange(n_taps) - half
    lp     = np.sinc(2 * cutoff * n) * np.blackman(n_taps)
    lp    /= lp.sum()
    hp     = -lp.copy()
    hp[half] += 1.0
    filtered = np.convolve(wav_np, hp.astype(np.float32), mode="same")
    return filtered.astype(np.float32)


# ── Step 5: LUFS normalization ────────────────────────────────────────────────
def rms_normalize(wav_np: np.ndarray, target_db: float = -23.0) -> np.ndarray:
    rms  = np.sqrt(np.mean(wav_np ** 2) + 1e-12)
    gain = 10 ** ((target_db - 20 * np.log10(rms)) / 20)
    return wav_np * gain


# ── VAD (energy-based) ────────────────────────────────────────────────────────
def energy_vad(wav: np.ndarray, sr: int,
               frame_ms: float = 30.0, hop_ms: float = 10.0,
               energy_threshold_db: float = -38.0,
               min_speech_ms: float = 300.0,
               context_ms: float = 100.0) -> list[tuple[int, int]]:
    """
    Returns list of (start_sample, end_sample) for each speech segment.
    Used both for trimming silence edges and segmenting long recordings.
    """
    frame_len  = int(sr * frame_ms  / 1000)
    hop_len    = int(sr * hop_ms    / 1000)
    min_frames = max(1, int(min_speech_ms / hop_ms))
    ctx_frames = max(1, int(context_ms   / hop_ms))
    n_frames   = (len(wav) - frame_len) // hop_len + 1

    if n_frames <= 0:
        return [(0, len(wav))]

    energy = np.array([
        np.sqrt(np.mean(wav[i*hop_len : i*hop_len+frame_len] ** 2) + 1e-12)
        for i in range(n_frames)
    ])
    is_speech = 20 * np.log10(energy) > energy_threshold_db

    # Context expansion — close short gaps
    for i in range(ctx_frames, len(is_speech) - ctx_frames):
        if is_speech[max(0, i-ctx_frames) : i+ctx_frames].any():
            is_speech[i] = True

    segments, in_seg, seg_start = [], False, 0
    for i, v in enumerate(is_speech):
        if v and not in_seg:
            in_seg = True; seg_start = i
        elif not v and in_seg:
            in_seg = False
            if i - seg_start >= min_frames:
                segments.append((seg_start * hop_len,
                                 min(i * hop_len + frame_len, len(wav))))
    if in_seg and len(is_speech) - seg_start >= min_frames:
        segments.append((seg_start * hop_len, len(wav)))

    return segments if segments else [(0, len(wav))]


# ── Full pipeline ─────────────────────────────────────────────────────────────
def _run_pipeline(wav: torch.Tensor, sr: int,
                  target_sr: int = SR) -> tuple[np.ndarray, int, int]:
    """
    Shared pipeline for both bytes and path inputs.
    Returns: (preprocessed_wav_np, raw_sr, raw_n_samples)
    """
    raw_sr       = sr
    raw_n_samples = wav.shape[-1]

    # 1+2: mono + resample
    if wav.shape[0] > 1:
        wav = wav.mean(dim=0, keepdim=True)
    if sr != target_sr:
        wav = AF.resample(wav, sr, target_sr)

    wav_np = wav.squeeze().numpy().astype(np.float32)

    # 3: HPF at 50 Hz
    wav_np = highpass_filter_50hz(wav_np, sr=target_sr)

    # 4: VAD-trim (strip silence edges, matching dataset preprocessing)
    segs = energy_vad(wav_np, target_sr)
    if segs:
        wav_np = wav_np[segs[0][0] : segs[-1][1]]
    if len(wav_np) < 160:
        wav_np = np.zeros(TARGET_SAMPLES, dtype=np.float32)

    # 5+6: LUFS normalize → peak normalize
    wav_np = rms_normalize(wav_np.astype(np.float64)).astype(np.float32)
    peak   = np.abs(wav_np).max()
    if peak > 1e-8:
        wav_np /= peak

    return wav_np, raw_sr, raw_n_samples


def preprocess_audio_bytes(audio_bytes: bytes,
                            target_sr: int = SR) -> tuple[np.ndarray, int, int]:
    """Load from in-memory bytes (uploaded file)."""
    buf = io.BytesIO(audio_bytes)
    try:
        wav, sr = torchaudio.load(buf)
    except Exception:
        import librosa
        buf.seek(0)
        y, sr = librosa.load(buf, sr=None, mono=True)
        wav = torch.from_numpy(y).unsqueeze(0)
    return _run_pipeline(wav, sr, target_sr)


def preprocess_audio_path(path: str,
                           target_sr: int = SR) -> tuple[np.ndarray, int, int]:
    """Load from server-side file path."""
    try:
        wav, sr = torchaudio.load(path)
    except Exception:
        import librosa
        y, sr = librosa.load(path, sr=None, mono=True)
        wav = torch.from_numpy(y).unsqueeze(0)
    return _run_pipeline(wav, sr, target_sr)
