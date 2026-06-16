"""
fft_jo.py
----------
FFT of Joint Orientation (FFTJO) — 8 and 16 bins.

Computes the orientation angle of each joint's bone over time, applies FFT,
and accumulates power into a non-linearly spaced frequency histogram.

Equivalent to: RVI_38_D_FFT_JO_8Bin.m  and  RVI_38_D_FFT_JO_16Bin.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import (J_RIGHT_ARM, J_LEFT_ARM, J_RIGHT_LEG, J_LEFT_LEG,
                    J_FULL_BODY_NO_ROOT, FFT_SAMPLING_RATE,
                    FFTJO_PWR_8, FFTJO_PWR_16)
from src.features.utils import fft_power_spectrum, assign_fft_bin_cumulative


def compute_fftjo_video(final_pose: np.ndarray,
                         parent_ids: np.ndarray,
                         num_bin: int,
                         pwr: float) -> dict:
    """
    Compute FFTJO histogram for a single video.

    For each frame, the bone (joint→parent) direction gives an orientation
    angle (degrees). FFT of that angle sequence is binned with power-law bins.
    """
    n_frames  = final_pose.shape[0]
    all_hists = {}

    for jid in J_FULL_BODY_NO_ROOT:
        pid = parent_ids[jid]
        if pid < 0:
            continue

        # Collect orientation angle per frame
        orientations = np.zeros(n_frames)
        for frm in range(n_frames):
            bone = final_pose[frm, jid, :] - final_pose[frm, pid, :]
            a, b = bone[0], bone[1]
            if (a ** 2 + b ** 2) == 0:
                cos_theta = 0.0
            else:
                cos_theta = a / np.sqrt(a ** 2 + b ** 2)
            orientations[frm] = np.degrees(np.arccos(np.clip(cos_theta, -1, 1)))

        # FFT + power-law binning (cumulative)
        P1, f = fft_power_spectrum(orientations, FFT_SAMPLING_RATE)
        max_f = float(f.max()) if len(f) > 0 else 1.0

        cur_hist = np.zeros(num_bin)
        for aa in range(len(f)):
            best = assign_fft_bin_cumulative(float(f[aa]), max_f, num_bin, pwr)
            cur_hist[best] += P1[aa]

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


def compute_fftjo(all_final_pose: dict,
                  parent_ids: np.ndarray,
                  num_bin: int,
                  verbose: bool = True) -> dict:
    """Compute FFTJO for all videos. Returns (n_videos, num_bin) matrices."""
    pwr    = FFTJO_PWR_8 if num_bin == 8 else FFTJO_PWR_16
    suffix = str(num_bin)
    collector = {k: [] for k in
                 ["RightElbow", "RightWrist", "LeftElbow", "LeftWrist",
                  "RightKnee",  "RightAnkle", "LeftKnee",  "LeftAnkle"]}

    n_vids = len(all_final_pose)
    for idx, (vid, pose) in enumerate(all_final_pose.items(), 1):
        if verbose:
            print(f"  [FFTJO-{num_bin}] Video {idx:02d}/{n_vids}...", end="\r")
        h = compute_fftjo_video(pose, parent_ids, num_bin, pwr)
        for key in collector:
            collector[key].append(h[key])

    if verbose:
        print(f"  [FFTJO-{num_bin}] Done.                          ")

    return {f"{k}{suffix}": np.stack(v, axis=0) for k, v in collector.items()}
