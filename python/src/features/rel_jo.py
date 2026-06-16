"""
rel_jo.py
----------
Relative Joint Orientation 2D (HORJO2D) — 8 and 16 bins.

For each pair of joints (aa, bb) in the first 15 joints, computes the
direction of the vector (joint_aa → joint_bb), bins it with cosine distance,
and accumulates into a per-joint histogram. The 15 histograms are concatenated
into one fused feature vector per video.

Equivalent to: RVI_38_D_Rel_JO2D_8Bin.m  and  RVI_38_D_Rel_JO2D_16Bin.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import J_REL_JOINTS, REL_SLICES_8, REL_SLICES_16
from src.features.utils import build_bin_vectors, get_hist_cosine


def compute_rel_jo_video(final_pose: np.ndarray, num_bin: int) -> np.ndarray:
    """
    Compute Relative Joint Orientation histogram for one video.

    Returns
    -------
    fused_hist : (15 * num_bin,)  — concatenated histograms for 15 joints.
    """
    n_frames  = final_pose.shape[0]
    bin_vecs  = build_bin_vectors(num_bin)   # (2, num_bin)
    n_joints  = len(J_REL_JOINTS)
    cur_hists = [np.zeros(num_bin) for _ in range(n_joints)]

    for frm in range(n_frames):
        for aa_idx, jid_aa in enumerate(J_REL_JOINTS):
            for jid_bb in J_REL_JOINTS:
                bone = final_pose[frm, jid_aa, :] - final_pose[frm, jid_bb, :]
                n    = np.linalg.norm(bone)
                if n > 0:
                    bone = bone / n
                    cur_hists[aa_idx] += get_hist_cosine(bone, bin_vecs)

    # Normalise each joint's histogram, then concatenate
    fused = []
    for h in cur_hists:
        total = h.sum()
        fused.append(h / total if total > 0 else h)
    return np.concatenate(fused)   # (15 * num_bin,)


def compute_rel_jo(all_final_pose: dict,
                   num_bin: int,
                   verbose: bool = True) -> dict:
    """
    Compute Rel_JO for all videos.

    Returns dict with:
      'Parts<N>'     : (n_vids, 15*num_bin) — full fused histograms
      'Larm<N>'  etc : (n_vids, num_bin)    — per-limb sub-features
    """
    suffix  = str(num_bin)
    slices  = REL_SLICES_8 if num_bin == 8 else REL_SLICES_16
    parts   = []

    n_vids = len(all_final_pose)
    for idx, (vid, pose) in enumerate(all_final_pose.items(), 1):
        if verbose:
            print(f"  [RelJO-{num_bin}] Video {idx:02d}/{n_vids}...", end="\r")
        parts.append(compute_rel_jo_video(pose, num_bin))

    if verbose:
        print(f"  [RelJO-{num_bin}] Done.                          ")

    parts_mat = np.stack(parts, axis=0)   # (n_vids, 15*num_bin)

    # Extract per-limb sub-matrices and fuse into arm/leg groups.
    # NOTE: naming mirrors MATLAB exactly (including its naming quirk):
    #   HORJO2D_Larm = LW + LE
    #   HORJO2D_Lleg = RW + RE   ← MATLAB naming (apparently swapped labels)
    #   HORJO2D_Rarm = LA + LK
    #   HORJO2D_Rleg = RA + RK
    LW = parts_mat[:, slices["LW"]]
    LE = parts_mat[:, slices["LE"]]
    RW = parts_mat[:, slices["RW"]]
    RE = parts_mat[:, slices["RE"]]
    LA = parts_mat[:, slices["LA"]]
    LK = parts_mat[:, slices["LK"]]
    RA = parts_mat[:, slices["RA"]]
    RK = parts_mat[:, slices["RK"]]

    return {
        f"Parts{suffix}":  parts_mat,
        f"Larm{suffix}":   LW + LE,
        f"Lleg{suffix}":   RW + RE,
        f"Rarm{suffix}":   LA + LK,
        f"Rleg{suffix}":   RA + RK,
    }
