"""
ang_dis.py
-----------
Angular Displacement (AngDis) — 8 and 16 bins.

Measures how much each joint's bone direction rotates between frames
separated by a fixed interval, then bins the rotation angle with
logarithmically-spaced thresholds.

Equivalent to: RVI_38_D_AngDis_8Bin.m  and  RVI_38_D_AngDis_16Bin.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import (J_RIGHT_ARM, J_LEFT_ARM, J_RIGHT_LEG, J_LEFT_LEG,
                    J_FULL_BODY_NO_ROOT, DISPLACEMENT_INTERVAL_ANGDIS)
from src.features.utils import build_ang_dis_bins, get_hist_discrete


def compute_angdis_video(final_pose: np.ndarray,
                          parent_ids: np.ndarray,
                          num_bin: int) -> dict:
    """
    Compute angular-displacement histograms for a single video.

    For each frame pair separated by `DISPLACEMENT_INTERVAL_ANGDIS` frames,
    compute the angle change in each joint's bone direction.
    """
    n_frames  = final_pose.shape[0]
    interval  = DISPLACEMENT_INTERVAL_ANGDIS
    ang_bins  = build_ang_dis_bins(num_bin)   # log-spaced thresholds
    all_hists = {}

    # MATLAB: frmRange = 1+interval:interval:length-1  (1-based)
    # Python 0-based: start = interval, step = interval, up to n_frames-1
    frame_range = range(interval, n_frames, interval)

    for jid in J_FULL_BODY_NO_ROOT:
        pid = parent_ids[jid]
        if pid < 0:
            continue
        cur_hist = np.zeros(num_bin)

        for frm in frame_range:
            bone     = final_pose[frm,          jid, :] - final_pose[frm,          pid, :]
            old_bone = final_pose[frm - interval, jid, :] - final_pose[frm - interval, pid, :]

            n1, n2 = np.linalg.norm(bone), np.linalg.norm(old_bone)
            if n1 > 0 and n2 > 0:
                bone     = bone / n1
                old_bone = old_bone / n2
                cos_t    = np.clip(np.dot(bone, old_bone), -1.0, 1.0)
                angle    = np.degrees(np.arccos(cos_t))
                cur_hist += get_hist_discrete(angle, ang_bins)

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


def compute_angdis(all_final_pose: dict,
                   parent_ids: np.ndarray,
                   num_bin: int,
                   verbose: bool = True) -> dict:
    """Compute AngDis for all videos. Returns (n_videos, num_bin) matrices."""
    suffix    = str(num_bin)
    collector = {k: [] for k in
                 ["RightElbow", "RightWrist", "LeftElbow", "LeftWrist",
                  "RightKnee",  "RightAnkle", "LeftKnee",  "LeftAnkle"]}

    n_vids = len(all_final_pose)
    for idx, (vid, pose) in enumerate(all_final_pose.items(), 1):
        if verbose:
            print(f"  [AngDis-{num_bin}] Video {idx:02d}/{n_vids}...", end="\r")
        h = compute_angdis_video(pose, parent_ids, num_bin)
        for key in collector:
            collector[key].append(h[key])

    if verbose:
        print(f"  [AngDis-{num_bin}] Done.                          ")

    return {f"{k}{suffix}": np.stack(v, axis=0) for k, v in collector.items()}
