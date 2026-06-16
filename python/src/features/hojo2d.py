"""
hojo2d.py
----------
Histogram of Joint Orientation 2D (HOJO2D) — 8 and 16 bins.

For each frame, computes the direction vector of each joint's "bone"
(joint → parent) and bins it using cosine-distance soft assignment.
The result is a normalised histogram per joint per video.

Equivalent to: RVI_38_D_HOJO2D_8Bin.m  and  RVI_38_D_HOJO2D_16Bin.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import J_RIGHT_ARM, J_LEFT_ARM, J_RIGHT_LEG, J_LEFT_LEG, J_FULL_BODY_NO_ROOT
from src.features.utils import build_bin_vectors, get_hist_hojo


def compute_hojo2d_video(final_pose: np.ndarray,
                          parent_ids: np.ndarray,
                          num_bin: int) -> dict:
    """
    Compute HOJO2D histograms for a single video.

    Parameters
    ----------
    final_pose : (n_frames, 21, 2)  — rotation-normalised poses
    parent_ids : (21,)              — 0-based parent joint indices (-1 = root)
    num_bin    : int                — 8 or 16

    Returns
    -------
    dict with keys 'RightElbow', 'RightWrist', 'LeftElbow', 'LeftWrist',
                   'RightKnee',  'RightAnkle', 'LeftKnee',  'LeftAnkle'
    Each value: np.ndarray (num_bin,)
    """
    n_frames  = final_pose.shape[0]
    bin_vecs  = build_bin_vectors(num_bin)           # (2, num_bin)
    all_hists = {}                                   # joint_idx → histogram

    for jid in J_FULL_BODY_NO_ROOT:
        pid = parent_ids[jid]
        if pid < 0:
            continue   # root has no parent, skip
        cur_hist = np.zeros(num_bin)

        for frm in range(n_frames):
            bone = final_pose[frm, jid, :] - final_pose[frm, pid, :]
            n    = np.linalg.norm(bone)
            if n > 0:
                bone = bone / n
                cur_hist += get_hist_hojo(bone, bin_vecs, share_weight=True)

        total = cur_hist.sum()
        all_hists[jid] = cur_hist / total if total > 0 else cur_hist

    def _pick(joint_group, which):
        """which='min' → elbow, 'max' → wrist/ankle/knee (distal joint)."""
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


def compute_hojo2d(all_final_pose: dict,
                   parent_ids: np.ndarray,
                   num_bin: int,
                   verbose: bool = True) -> dict:
    """
    Compute HOJO2D for all videos. Returns feature matrices (38 × num_bin each).

    Returns
    -------
    dict with keys like 'RightElbow8' / 'RightElbow16', etc.
    Shape of each value: (n_videos, num_bin)
    """
    suffix    = str(num_bin)
    collector = {k: [] for k in
                 ["RightElbow", "RightWrist", "LeftElbow", "LeftWrist",
                  "RightKnee",  "RightAnkle", "LeftKnee",  "LeftAnkle"]}

    n_vids = len(all_final_pose)
    for idx, (vid, pose) in enumerate(all_final_pose.items(), 1):
        if verbose:
            print(f"  [HOJO2D-{num_bin}] Video {idx:02d}/{n_vids}...", end="\r")
        h = compute_hojo2d_video(pose, parent_ids, num_bin)
        for key in collector:
            collector[key].append(h[key])

    if verbose:
        print(f"  [HOJO2D-{num_bin}] Done.                          ")

    return {f"{k}{suffix}": np.stack(v, axis=0) for k, v in collector.items()}
