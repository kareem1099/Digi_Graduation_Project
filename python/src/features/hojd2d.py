"""
hojd2d.py
----------
Histogram of Joint Displacement 2D (HOJD2D) — 8 and 16 bins.

Computes how fast each joint moves (speed) between frames sampled every 5
frames, then bins that speed into a speed-magnitude histogram.

Equivalent to: RVI_38_D_HOJD2D_8Bin.m  and  RVI_38_D_HOJD2D_16Bin.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import (J_RIGHT_ARM, J_LEFT_ARM, J_RIGHT_LEG, J_LEFT_LEG,
                    J_FULL_BODY_ALL, HOJD_BIN_INC)


def _speed_to_bin(speed: float, num_bin: int, bin_inc: float) -> int:
    """Map a speed value to a 0-based bin index (same logic as MATLAB ifelse chain)."""
    for k in range(1, num_bin):
        if speed < k * bin_inc:
            return k - 1
    return num_bin - 1


def compute_hojd2d_video(final_pose: np.ndarray, num_bin: int) -> dict:
    """
    Compute HOJD2D histograms for a single video.

    Speed is measured every 5 frames (MATLAB: frm = 6:5:frmLength, i.e., frame
    pairs (5,0),(10,5),... which in 0-based Python is pairs (5,0),(10,5),...).

    Parameters
    ----------
    final_pose : (n_frames, 21, 2)
    num_bin    : 8 or 16

    Returns
    -------
    dict with keys 'RightElbow', 'RightWrist', etc.  Each value: (num_bin,)
    """
    n_frames = final_pose.shape[0]
    all_hists = {}

    for jid in J_FULL_BODY_ALL:
        cur_hist = np.zeros(num_bin)
        # MATLAB: for frm = 6:5:frmLength  (1-based, step 5)
        # → Python 0-based: frm in range(5, n_frames, 5)
        for frm in range(5, n_frames, 5):
            vel   = final_pose[frm, jid, :] - final_pose[frm - 5, jid, :]
            speed = float(np.linalg.norm(vel))
            best  = _speed_to_bin(speed, num_bin, HOJD_BIN_INC)
            cur_hist[best] += 1

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


def compute_hojd2d(all_final_pose: dict,
                   num_bin: int,
                   verbose: bool = True) -> dict:
    """Compute HOJD2D for all videos. Returns (n_videos, num_bin) matrices."""
    suffix    = str(num_bin)
    collector = {k: [] for k in
                 ["RightElbow", "RightWrist", "LeftElbow", "LeftWrist",
                  "RightKnee",  "RightAnkle", "LeftKnee",  "LeftAnkle"]}

    n_vids = len(all_final_pose)
    for idx, (vid, pose) in enumerate(all_final_pose.items(), 1):
        if verbose:
            print(f"  [HOJD2D-{num_bin}] Video {idx:02d}/{n_vids}...", end="\r")
        h = compute_hojd2d_video(pose, num_bin)
        for key in collector:
            collector[key].append(h[key])

    if verbose:
        print(f"  [HOJD2D-{num_bin}] Done.                          ")

    return {f"{k}{suffix}": np.stack(v, axis=0) for k, v in collector.items()}
