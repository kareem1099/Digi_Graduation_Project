"""
a_preprocessing.py
-------------------
Step A: Load JSON keypoint files for each video, filter low-confidence frames,
interpolate missing values using Akima spline, and smooth with a moving average.

Equivalent to: RVI_38_A_Pre_processing.m
"""

import json
import os
import glob
import numpy as np
import pandas as pd
from scipy.interpolate import Akima1DInterpolator

import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import (
    JSON_DIR, NUM_VIDEOS, JOINT_RANGE, CONFIDENCE_MARGIN, SMOOTH_WINDOW
)


def _moving_average(arr: np.ndarray, window: int) -> np.ndarray:
    """
    Centered moving average with shrinking window at boundaries.
    Matches MATLAB's movmean(x, window) behaviour.
    """
    return (
        pd.Series(arr)
        .rolling(window, center=True, min_periods=1)
        .mean()
        .to_numpy()
    )


def load_video_frames(video_id: int) -> list[np.ndarray]:
    """
    Load all JSON keypoint files for one video.

    Returns
    -------
    frames : list of np.ndarray, shape (25, 3)
        Each element is one frame: 25 joints × [x, y, confidence].
    """
    pattern = os.path.join(
        JSON_DIR,
        f"RVI_38_{video_id:04d}_*_keypoints.json"
    )
    files = sorted(glob.glob(pattern))
    frames = []
    for f in files:
        with open(f, "r") as fh:
            data = json.load(fh)
        kp = np.array(data["people"][0]["pose_keypoints_2d"])
        # Reshape from flat [x0,y0,c0, x1,y1,c1, ...] to (25, 3)
        frames.append(kp.reshape(25, 3))
    return frames


def preprocess_video(video_id: int) -> dict:
    """
    Pre-process one video:
      1. Load all frames.
      2. For each selected joint, filter low-confidence frames.
      3. Interpolate X and Y using Akima spline over all frame positions.
      4. Smooth with a centered moving average.

    Returns
    -------
    dict with keys:
        'pose' : np.ndarray, shape (n_frames, 21, 3)
            Processed pose per frame. Columns 0=x, 1=y, 2=confidence (raw).
        'n_frames' : int
    """
    frames = load_video_frames(video_id)
    n_frames = len(frames)

    # Stack all frames: shape (n_frames, 25, 3)
    all_kp = np.stack(frames, axis=0)   # (n_frames, 25, 3)

    # Frame index arrays — MATLAB: idX = 0:frmLength, xx = 1:length(idX)
    idx = np.arange(0, n_frames)        # 0, 1, …, n_frames-1
    xx  = np.arange(1, n_frames + 1)   # 1, 2, …, n_frames  (interpolation query points)

    # Output array: keep only the 21 selected joints
    processed = np.zeros((n_frames, 21, 3))

    for out_j, orig_j in enumerate(JOINT_RANGE):
        confi = all_kp[:, orig_j, 2]   # shape (n_frames,)
        x_raw = all_kp[:, orig_j, 0]
        y_raw = all_kp[:, orig_j, 1]

        mean_conf = float(np.mean(confi))
        good_mask = confi >= (mean_conf - CONFIDENCE_MARGIN)
        good_idx  = idx[good_mask]
        good_x    = x_raw[good_mask]
        good_y    = y_raw[good_mask]

        # Interpolate — Akima is the closest scipy equivalent to MATLAB's 'makima'
        if len(good_idx) >= 2:
            interp_x = Akima1DInterpolator(good_idx, good_x)
            interp_y = Akima1DInterpolator(good_idx, good_y)
            smooth_x = interp_x(xx, extrapolate=True)
            smooth_y = interp_y(xx, extrapolate=True)
        else:
            # Fallback: just use raw values
            smooth_x = x_raw.copy().astype(float)
            smooth_y = y_raw.copy().astype(float)

        # Apply centered moving average (window = SMOOTH_WINDOW)
        smooth_x = _moving_average(smooth_x, SMOOTH_WINDOW)
        smooth_y = _moving_average(smooth_y, SMOOTH_WINDOW)

        processed[:, out_j, 0] = smooth_x
        processed[:, out_j, 1] = smooth_y
        processed[:, out_j, 2] = confi   # keep raw confidence

    return {"pose": processed, "n_frames": n_frames}


def run_preprocessing(verbose: bool = True) -> dict:
    """
    Run pre-processing for all 38 videos.

    Returns
    -------
    all_pose : dict  {video_id (1-38) : np.ndarray (n_frames, 21, 3)}
    """
    all_pose = {}
    for vid in range(1, NUM_VIDEOS + 1):
        if verbose:
            print(f"  [A] Pre-processing video {vid:02d}/{NUM_VIDEOS}...", end="\r")
        result = preprocess_video(vid)
        all_pose[vid] = result["pose"]   # (n_frames, 21, 3)
    if verbose:
        print(f"  [A] Pre-processing complete. {NUM_VIDEOS} videos processed.  ")
    return all_pose
