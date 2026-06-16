"""
c_normalise_rotation.py
------------------------
Step C: Rotate each frame so the spine vector (neck → midHip) aligns with
the positive Y-axis, removing camera-angle bias.

Equivalent to: RVI_38_C_NormaliseRotation.m
"""

import numpy as np
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import PARENT_IDS


def _rot_z(theta_deg: float) -> np.ndarray:
    """2-D rotation matrix for angle theta (degrees)."""
    t = np.deg2rad(theta_deg)
    return np.array([[np.cos(t), -np.sin(t)],
                     [np.sin(t),  np.cos(t)]])


def normalise_rotation_video(corrected_pose: np.ndarray,
                              alignment_vec: np.ndarray) -> np.ndarray:
    """
    Rotate every frame's skeleton so the spine aligns with Y-axis.

    Parameters
    ----------
    corrected_pose : np.ndarray (n_frames, 21, 2)
        Root-centred poses from Step B.
    alignment_vec  : np.ndarray (n_frames, 2)
        Spine vector (neck − midHip) per frame.

    Returns
    -------
    final_pose : np.ndarray (n_frames, 21, 2)
        Rotation-normalised poses.
    """
    n_frames  = corrected_pose.shape[0]
    final     = np.zeros_like(corrected_pose)
    y_axis    = np.array([0.0, 1.0])

    for frm in range(n_frames):
        vec = alignment_vec[frm]                # spine direction (2D)
        n   = np.linalg.norm(vec)
        if n < 1e-9:
            # Degenerate frame: no rotation
            final[frm] = corrected_pose[frm]
            continue

        # Angle between spine and Y-axis (degrees)
        cos_t = np.clip(np.dot(vec, y_axis) / n, -1.0, 1.0)
        theta  = np.degrees(np.arccos(cos_t))

        # Sign: cross product z-component tells us direction of rotation
        cross_z = vec[0] * y_axis[1] - vec[1] * y_axis[0]
        sign = -1.0 if cross_z < 0 else 1.0

        rM = _rot_z(sign * theta)               # 2×2 rotation matrix

        # Apply rotation to every joint: (rM @ joint.T).T
        final[frm] = (rM @ corrected_pose[frm].T).T   # (21, 2)

    return final


def run_normalise_rotation(alignment_results: dict,
                           verbose: bool = True) -> dict:
    """
    Run rotation normalisation for all videos.

    Parameters
    ----------
    alignment_results : dict {vid: {'corrected_pose', 'alignment_vec', 'root'}}

    Returns
    -------
    processed : dict {vid: np.ndarray (n_frames, 21, 2)}
        'allFinalPose' equivalent — ready for feature extraction.
    Also returns pID array (same for all videos).
    """
    processed = {}
    n_vids    = len(alignment_results)
    for idx, (vid, data) in enumerate(alignment_results.items(), 1):
        if verbose:
            print(f"  [C] Normalising rotation for video {idx:02d}/{n_vids}...",
                  end="\r")
        processed[vid] = normalise_rotation_video(
            data["corrected_pose"],
            data["alignment_vec"]
        )
    if verbose:
        print(f"  [C] Rotation normalisation complete. {n_vids} videos.        ")

    return processed, np.array(PARENT_IDS)
