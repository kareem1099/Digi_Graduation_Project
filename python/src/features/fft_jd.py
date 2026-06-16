"""
fft_jd.py
----------
FFT of Joint Displacement (FFTJD) — 8 and 16 bins.

Samples joint speed at regular intervals, applies FFT, and bins
the power into non-linearly spaced frequency bins.

8-bin  uses pwr=2  with ABSOLUTE bin boundaries.
16-bin uses pwr=1.5 with CUMULATIVE bin boundaries.

Equivalent to: RVI_38_D_FFT_JD_8Bin.m  and  RVI_38_D_FFT_JD_16Bin.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import (J_RIGHT_ARM, J_LEFT_ARM, J_RIGHT_LEG, J_LEFT_LEG,
                    J_FULL_BODY_ALL, FFT_SAMPLING_RATE,
                    FFTJD_PWR_8, FFTJD_PWR_16,
                    FFTJD_STEP_8, FFTJD_STEP_16)
from src.features.utils import (fft_power_spectrum,
                                 assign_fft_bin_absolute,
                                 assign_fft_bin_cumulative)


def compute_fftjd_video(final_pose: np.ndarray,
                         num_bin: int,
                         pwr: float,
                         step: int,
                         use_cumulative: bool) -> dict:
    """
    Compute FFTJD histograms for a single video.

    Speed is sampled every `step` frames (MATLAB: frm = 2:step:frmLength,
    pairs of consecutive frames), producing a sparse speed sequence.
    The full-length speed array is kept (zeros for un-sampled frames) and
    FFT is applied to the full array — matching MATLAB's behaviour where
    `speed` is indexed by frame number within the pre-allocated array.
    """
    n_frames  = final_pose.shape[0]
    all_hists = {}

    for jid in J_FULL_BODY_ALL:
        # Build sparse speed signal (MATLAB allocates `speed` lazily)
        # MATLAB: for frm = 2:step:frmLength  → frm pairs (frm, frm-1)
        speed = np.zeros(n_frames)
        for frm in range(1, n_frames, step):
            vel        = final_pose[frm, jid, :] - final_pose[frm - 1, jid, :]
            speed[frm] = float(np.linalg.norm(vel))

        P1, f = fft_power_spectrum(speed, FFT_SAMPLING_RATE)
        max_f = float(f.max()) if len(f) > 0 else 1.0

        cur_hist = np.zeros(num_bin)
        for bb in range(len(f)):
            if use_cumulative:
                best = assign_fft_bin_cumulative(float(f[bb]), max_f, num_bin, pwr)
            else:
                best = assign_fft_bin_absolute(float(f[bb]), max_f, num_bin, pwr)
            cur_hist[best] += P1[bb]

        total = cur_hist.sum()
        all_hists[jid] = cur_hist / total if total > 0 else cur_hist

    def _pick(joint_group, which):
        jid = min(joint_group) if which == "min" else max(joint_group)
        return all_hists.get(jid, np.zeros(num_bin))

    return {
        "RightElbow": _pick(J_RIGHT_ARM, "min"),
        "RightWrist": _pick(J_RIGHT_ARM, "max"),
        "LeftElbow":  _pick(J_LEFT_ARM,  "min"),
        "LeftWrist":  _pick(J_LEFT_ARM,  "max"),
        "RightKnee":  _pick(J_RIGHT_LEG, "min"),
        "RightAnkle": _pick(J_RIGHT_LEG, "max"),
        "LeftKnee":   _pick(J_LEFT_LEG,  "min"),
        "LeftAnkle":  _pick(J_LEFT_LEG,  "max"),
    }


def compute_fftjd(all_final_pose: dict,
                  num_bin: int,
                  verbose: bool = True) -> dict:
    """Compute FFTJD for all videos. Returns (n_videos, num_bin) matrices."""
    if num_bin == 8:
        pwr, step, cumulative = FFTJD_PWR_8, FFTJD_STEP_8, False
    else:
        pwr, step, cumulative = FFTJD_PWR_16, FFTJD_STEP_16, True

    suffix    = str(num_bin)
    collector = {k: [] for k in
                 ["RightElbow", "RightWrist", "LeftElbow", "LeftWrist",
                  "RightKnee",  "RightAnkle", "LeftKnee",  "LeftAnkle"]}

    n_vids = len(all_final_pose)
    for idx, (vid, pose) in enumerate(all_final_pose.items(), 1):
        if verbose:
            print(f"  [FFTJD-{num_bin}] Video {idx:02d}/{n_vids}...", end="\r")
        h = compute_fftjd_video(pose, num_bin, pwr, step, cumulative)
        for key in collector:
            collector[key].append(h[key])

    if verbose:
        print(f"  [FFTJD-{num_bin}] Done.                          ")

    return {f"{k}{suffix}": np.stack(v, axis=0) for k, v in collector.items()}
