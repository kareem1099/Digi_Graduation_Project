"""
config.py
---------
Central configuration for the Cerebral Palsy RVI-38 Python pipeline.
All paths and constants are defined here so nothing is hard-coded elsewhere.
"""

import os

# ── Base paths ───────────────────────────────────────────────────────────────
# Root of the cerebral_balsy project (one level above this python/ folder)
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# Folder containing the RVI-38 JSON keypoint files
JSON_DIR = os.path.join(PROJECT_ROOT, "data", "25J_RVI38_Full_Processed")

# MATLAB labels file (we read it with scipy.io.loadmat)
LABELS_MAT = os.path.join(
    PROJECT_ROOT,
    "code", "RVI_38", "00_25J_RVI_38_Full", "RVI_38_labels.mat"
)

# Where computed feature .npz files are saved
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "outputs", "features")

# ── Dataset parameters ───────────────────────────────────────────────────────
NUM_VIDEOS = 38          # RVI-38 dataset: 38 videos
NUM_OPENPOSE_JOINTS = 25 # OpenPose outputs 25 joints

# Joint indices (0-based) selected from the 25 OpenPose joints.
# MATLAB: jointRange = [1:15, 20:25]  →  Python: [0..14, 19..24]
JOINT_RANGE = list(range(0, 15)) + list(range(19, 25))  # 21 joints

# After B_Alignment, joints are stacked in JOINT_RANGE order → indices 0-20.
# pID[j] = parent joint index (0-based) in the 21-joint space.
# Root (midHip, position 8) has pID = -1 (no parent).
#
# MATLAB (1-based): [2 9 2 3 4 2 6 7 0 9 10 11 9 13 14 15 15 15 12 12 12]
# Python (0-based): subtract 1 from each; 0 → -1
PARENT_IDS = [1, 8, 1, 2, 3, 1, 5, 6, -1, 8, 9, 10, 8, 12, 13, 14, 14, 14, 11, 11, 11]

# Joint groups used in feature extraction (0-based in the 21-joint space)
# MATLAB: jRightArm=4:5, jLeftArm=7:8, jRightLeg=11:12, jLeftLeg=14:15
J_RIGHT_ARM  = [3, 4]    # rElbow, rWrist
J_LEFT_ARM   = [6, 7]    # lElbow, lWrist
J_RIGHT_LEG  = [10, 11]  # rKnee,  rAnkle
J_LEFT_LEG   = [13, 14]  # lKnee,  lAnkle

# Full body (all joints except root=8) used in orientation/AngDis features
# MATLAB: jFullBody = [1:8 10:21]  →  Python: [0..7, 9..20]
J_FULL_BODY_NO_ROOT = list(range(0, 8)) + list(range(9, 21))

# Full body INCLUDING root used in displacement/FFT features
# MATLAB: jFullBody = 1:21  →  Python: 0..20
J_FULL_BODY_ALL = list(range(0, 21))

# Joints used for relative-orientation features (first 15 of the 21)
# MATLAB: allJoints = [1:15]  →  Python: 0..14
J_REL_JOINTS = list(range(0, 15))

# ── Pre-processing parameters ────────────────────────────────────────────────
CONFIDENCE_MARGIN = 0.07   # frames with conf >= mean-margin are kept
SMOOTH_WINDOW = 5           # moving-average window for smoothing

# ── Feature parameters ───────────────────────────────────────────────────────
# Angular-displacement binning parameters (used in AngDis and Rel_JOAngDis)
DISPLACEMENT_INTERVAL_ANGDIS = 10   # frame gap for AngDis feature
DISPLACEMENT_INTERVAL_RELANG = 7    # frame gap for Rel_JOAngDis feature

# HOJD2D speed binning increment (pixels per step)
HOJD_BIN_INC = 2

# FFT parameters
FFT_SAMPLING_RATE = 50   # Fs = 50 (assumed from MATLAB)
FFTJO_PWR_8  = 20        # power-law exponent for FFT_JO 8-bin
FFTJO_PWR_16 = 20
FFTJD_PWR_8  = 2         # power-law exponent for FFT_JD 8-bin
FFTJD_PWR_16 = 1.5

# Frame step used when sampling speeds for FFT
FFTJD_STEP_8  = 6   # MATLAB: frm = 2:6:frmLength
FFTJD_STEP_16 = 10  # MATLAB: frm = 2:10:frmLength

# ── Column slices for Rel_JO and Rel_JOAngDis features (0-based) ─────────────
# There are 15 joints × numBin columns in the fused histogram.
# Joints are ordered 0-14; each block is numBin wide.

def _col_slice(joint_0based, num_bin):
    """Return Python slice for a given 0-based joint index and bin count."""
    start = joint_0based * num_bin
    return slice(start, start + num_bin)

# 8-bin slices (MATLAB 1-based: joint 4=RE,5=RW,7=LE,8=LW,11=RK,12=RA,14=LK,15=LA)
REL_SLICES_8 = {
    "RE": _col_slice(3, 8),   # rElbow
    "RW": _col_slice(4, 8),   # rWrist
    "LE": _col_slice(6, 8),   # lElbow
    "LW": _col_slice(7, 8),   # lWrist
    "RK": _col_slice(10, 8),  # rKnee
    "RA": _col_slice(11, 8),  # rAnkle
    "LK": _col_slice(13, 8),  # lKnee
    "LA": _col_slice(14, 8),  # lAnkle
}

# 16-bin slices
REL_SLICES_16 = {
    "RE": _col_slice(3, 16),
    "RW": _col_slice(4, 16),
    "LE": _col_slice(6, 16),
    "LW": _col_slice(7, 16),
    "RK": _col_slice(10, 16),
    "RA": _col_slice(11, 16),
    "LK": _col_slice(13, 16),
    "LA": _col_slice(14, 16),
}

# ── Classification parameters ────────────────────────────────────────────────
ENSEMBLE_N_CYCLES = 11
ENSEMBLE_LEARN_RATE = 0.13603
ENSEMBLE_MIN_LEAF = 2
ENSEMBLE_MAX_SPLITS = 2
