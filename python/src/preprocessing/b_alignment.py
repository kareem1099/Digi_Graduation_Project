"""
b_alignment.py
--------------
Step B: Root-centre the skeleton (subtract midHip position from all joints)
and compute the spine alignment vector (neck − midHip) for later rotation.

Equivalent to: RVI_38_B_Alignment.m

Joint layout after Step A (21 joints, 0-based):
  Index  |  Name            | Original OpenPose idx (0-based)
  -------|------------------|---------------------------------
    0    | nose             | 0
    1    | neck             | 1
    2    | rShoulder        | 2
    3    | rElbow           | 3
    4    | rWrist           | 4
    5    | lShoulder        | 5
    6    | lElbow           | 6
    7    | lWrist           | 7
    8    | midHip  (root)   | 8
    9    | rHip             | 9
   10    | rKnee            | 10
   11    | rAnkle           | 11
   12    | lHip             | 12
   13    | lKnee            | 13
   14    | lAnkle           | 14
   15    | LBigToe          | 19
   16    | LSmallToe        | 20
   17    | LHeel            | 21
   18    | RBigToe          | 22
   19    | RSmallToe        | 23
   20    | RHeel            | 24
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

# In the 21-joint array, joint index 1 = neck, index 8 = midHip
NECK_IDX   = 1   # MATLAB joint 2  → 0-based 1
MIDHIP_IDX = 8   # MATLAB joint 9  → 0-based 8


def align_video(pose: np.ndarray) -> dict:
    """
    Root-centre one video's pose sequence.

    Parameters
    ----------
    pose : np.ndarray, shape (n_frames, 21, 3)
        Interpolated + smoothed pose from Step A.

    Returns
    -------
    dict with:
        'corrected_pose' : np.ndarray (n_frames, 21, 2)
            XY positions relative to midHip root.
        'alignment_vec'  : np.ndarray (n_frames, 2)
            Spine vector (neck − midHip) per frame.
        'root'           : np.ndarray (n_frames, 2)
            midHip position per frame (before subtraction).
    """
    n_frames = pose.shape[0]

    root          = pose[:, MIDHIP_IDX, :2].copy()          # (n_frames, 2)
    alignment_vec = pose[:, NECK_IDX, :2] - root             # (n_frames, 2)

    # Subtract root from all joints → root-relative XY
    corrected = pose[:, :, :2] - root[:, np.newaxis, :]      # (n_frames, 21, 2)

    return {
        "corrected_pose": corrected,
        "alignment_vec":  alignment_vec,
        "root":           root,
    }


def run_alignment(all_pose: dict, verbose: bool = True) -> dict:
    """
    Run alignment for all videos.

    Parameters
    ----------
    all_pose : dict  {vid: np.ndarray (n_frames, 21, 3)}

    Returns
    -------
    results : dict  {vid: {'corrected_pose', 'alignment_vec', 'root'}}
    """
    results = {}
    n_vids  = len(all_pose)
    for idx, (vid, pose) in enumerate(all_pose.items(), 1):
        if verbose:
            print(f"  [B] Aligning video {idx:02d}/{n_vids}...", end="\r")
        results[vid] = align_video(pose)
    if verbose:
        print(f"  [B] Alignment complete. {n_vids} videos aligned.          ")
    return results
