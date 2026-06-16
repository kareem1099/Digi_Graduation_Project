"""
run_classification.py
----------------------
Entry point — Step 2.

Loads the saved feature matrices and labels, builds fusion feature sets,
then runs LOOCV classification with 7 classifiers.

Usage:
    cd cerebral_balsy/python
    python run_classification.py
"""

import os
import sys
import time
import numpy as np
import scipy.io

sys.path.insert(0, os.path.dirname(__file__))

from config import OUTPUT_DIR, LABELS_MAT
from src.classification.feature_fusion import build_feature_sets
from src.classification.classifier     import run_loocv, print_results


def load_features(npz_path: str) -> dict:
    """Load the .npz feature file and map keys to the naming convention
    expected by build_feature_sets()."""
    raw = np.load(npz_path)

    # Map saved npz keys -> internal naming used by feature_fusion.py
    # Convention used in feature_fusion.py:
    #   HOJO2D  : 'LeftWrist8', 'LeftElbow8', ...
    #   HOJD2D  : 'LeftWrist8_d', ...
    #   FFTJO   : 'LeftWrist8_fjo', ...
    #   FFTJD   : 'LeftWrist8_fjd', ...
    #   AngDis  : 'LeftWrist8_ang', ...
    #   Rel_JO  : 'Larm8_rjo', ...
    #   Rel_JOAD: 'Larm8_rjad', ...

    feats = {}

    joint_map = {
        "RightElbow": "RightElbow", "RightWrist": "RightWrist",
        "LeftElbow":  "LeftElbow",  "LeftWrist":  "LeftWrist",
        "RightKnee":  "RightKnee",  "RightAnkle": "RightAnkle",
        "LeftKnee":   "LeftKnee",   "LeftAnkle":  "LeftAnkle",
    }

    for bins in [8, 16]:
        for jname in joint_map:
            # HOJO2D
            key = f"hojo_{jname}{bins}"
            if key in raw:
                feats[f"{jname}{bins}"] = raw[key]

            # HOJD2D
            key = f"hojd_{jname}{bins}"
            if key in raw:
                feats[f"{jname}{bins}_d"] = raw[key]

            # FFTJO
            key = f"fftjo_{jname}{bins}"
            if key in raw:
                feats[f"{jname}{bins}_fjo"] = raw[key]

            # FFTJD
            key = f"fftjd_{jname}{bins}"
            if key in raw:
                feats[f"{jname}{bins}_fjd"] = raw[key]

            # AngDis
            key = f"angdis_{jname}{bins}"
            if key in raw:
                feats[f"{jname}{bins}_ang"] = raw[key]

        # Rel_JO limb groups
        for limb in ["Larm", "Lleg", "Rarm", "Rleg"]:
            key = f"reljo_{limb}{bins}"
            if key in raw:
                feats[f"{limb}{bins}_rjo"] = raw[key]

            key = f"reljoad_{limb}{bins}"
            if key in raw:
                feats[f"{limb}{bins}_rjad"] = raw[key]

    return feats


def load_labels() -> np.ndarray:
    """Load binary labels (0=healthy, 1=CP) from the MATLAB .mat file."""
    mat = scipy.io.loadmat(LABELS_MAT)
    labels = mat["labels"].flatten().astype(int)
    return labels


def main():
    t0 = time.time()

    print("\n" + "="*60)
    print("  Cerebral Palsy RVI-38 — Classification Pipeline")
    print("="*60 + "\n")

    # ── Load saved features ──────────────────────────────────────────────────
    npz_path = os.path.join(OUTPUT_DIR, "RVI_38_features.npz")
    if not os.path.exists(npz_path):
        print(f"ERROR: Feature file not found: {npz_path}")
        print("  Please run run_feature_extraction.py first.\n")
        sys.exit(1)

    print("[Load] Loading feature matrices...")
    feats = load_features(npz_path)
    print(f"       Loaded {len(feats)} feature arrays.")

    print("[Load] Loading labels...")
    labels = load_labels()
    print(f"       {len(labels)} videos  |  "
          f"{(labels==1).sum()} CP  |  {(labels==0).sum()} healthy\n")

    # ── Build fusion feature sets ────────────────────────────────────────────
    print("[Fuse] Building feature fusion matrices...")
    sets = build_feature_sets(feats)
    print(f"       PoseVelocity fusion shape: {sets['PoseVelFusion'].shape}\n")

    # ── Classification: run on PoseVelocityFusion (best per paper) ───────────
    # To run all three fusion sets, loop over all keys.
    fusion_sets = [
        (sets["PoseVelFusion"],  sets["PoseVelFusion_Lbl"]),
        (sets["PoseFusion"],     sets["PoseFusion_Lbl"]),
        (sets["VelFusion"],      sets["VelFusion_Lbl"]),
    ]

    all_results = {}
    for X, lbl in fusion_sets:
        print(f"[Classify] Running LOOCV for '{lbl}' "
              f"(shape={X.shape})...")
        res = run_loocv(X, labels, verbose=True)
        all_results[lbl] = res
        print_results(lbl, res)

    elapsed = time.time() - t0
    print(f"DONE Classification complete in {elapsed:.1f}s\n")


if __name__ == "__main__":
    main()
