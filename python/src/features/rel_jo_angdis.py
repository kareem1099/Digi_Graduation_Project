"""
rel_jo_angdis.py
-----------------
Relative Joint Orientation + Angular Displacement (HORJAD2D) — 8 and 16 bins.

Similar to rel_jo.py but measures how much the relative joint direction
CHANGES between frames separated by a fixed interval, rather than the
absolute direction. Bins the change angle with logarithmic thresholds.

Equivalent to: RVI_38_D_Rel_JOAngDis_8Bin.m  and  RVI_38_D_Rel_JOAngDis_16Bin.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import J_REL_JOINTS, REL_SLICES_8, REL_SLICES_16, DISPLACEMENT_INTERVAL_RELANG
from src.features.utils import build_ang_dis_bins, get_hist_discrete


def compute_rel_jo_angdis_video(final_pose: np.ndarray,
                                 num_bin: int) -> np.ndarray:
    """
    Compute Relative Joint Orientation + AngDis histogram for one video.

    Returns
    -------
    fused_hist : (15 * num_bin,)
    """
    n_frames  = final_pose.shape[0]
    interval  = DISPLACEMENT_INTERVAL_RELANG
    ang_bins  = build_ang_dis_bins(num_bin)
    n_joints  = len(J_REL_JOINTS)
    cur_hists = [np.zeros(num_bin) for _ in range(n_joints)]

    # MATLAB: frmRange = 1+interval:interval:frmLength  (1-based)
    frame_range = range(interval, n_frames, interval)

    for frm in frame_range:
        for aa_idx, jid_aa in enumerate(J_REL_JOINTS):
            for jid_bb in J_REL_JOINTS:
                bone     = (final_pose[frm,           jid_aa, :]
                            - final_pose[frm,           jid_bb, :])
                old_bone = (final_pose[frm - interval, jid_aa, :]
                            - final_pose[frm - interval, jid_bb, :])

                n1, n2 = np.linalg.norm(bone), np.linalg.norm(old_bone)
                if n1 > 0:
                    bone     = bone / n1
                    old_bone = old_bone / n2 if n2 > 0 else old_bone
                    cos_t    = np.clip(np.dot(bone, old_bone), -1.0, 1.0)
                    angle    = np.degrees(np.arccos(cos_t))
                    cur_hists[aa_idx] += get_hist_discrete(angle, ang_bins)

    fused = []
    for h in cur_hists:
        total = h.sum()
        fused.append(h / total if total > 0 else h)
    return np.concatenate(fused)   # (15 * num_bin,)


def compute_rel_jo_angdis(all_final_pose: dict,
                           num_bin: int,
                           verbose: bool = True) -> dict:
    """
    Compute Rel_JO_AngDis for all videos.

    Returns dict with 'Parts<N>', 'Larm<N>', 'Lleg<N>', 'Rarm<N>', 'Rleg<N>'.
    """
    suffix = str(num_bin)
    slices = REL_SLICES_8 if num_bin == 8 else REL_SLICES_16
    parts  = []

    n_vids = len(all_final_pose)
    for idx, (vid, pose) in enumerate(all_final_pose.items(), 1):
        if verbose:
            print(f"  [RelJOAngDis-{num_bin}] Video {idx:02d}/{n_vids}...", end="\r")
        parts.append(compute_rel_jo_angdis_video(pose, num_bin))

    if verbose:
        print(f"  [RelJOAngDis-{num_bin}] Done.                          ")

    parts_mat = np.stack(parts, axis=0)   # (n_vids, 15*num_bin)

    LW = parts_mat[:, slices["LW"]]
    LE = parts_mat[:, slices["LE"]]
    RW = parts_mat[:, slices["RW"]]
    RE = parts_mat[:, slices["RE"]]
    LA = parts_mat[:, slices["LA"]]
    LK = parts_mat[:, slices["LK"]]
    RA = parts_mat[:, slices["RA"]]
    RK = parts_mat[:, slices["RK"]]

    return {
        f"Parts{suffix}": parts_mat,
        f"Larm{suffix}":  LW + LE,
        f"Lleg{suffix}":  LA + LK,
        f"Rarm{suffix}":  RW + RE,
        f"Rleg{suffix}":  RA + RK,
    }
