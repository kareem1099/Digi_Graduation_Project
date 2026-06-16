"""
run_feature_extraction.py
--------------------------
Entry point — Step 1.

Runs the full preprocessing and feature extraction pipeline for the RVI-38
dataset and saves all 14 feature matrices to outputs/features/.

Usage:
    cd cerebral_balsy/python
    python run_feature_extraction.py
"""

import os
import sys
import time
import numpy as np

# Make sure the python/ folder is on the path so all imports work
sys.path.insert(0, os.path.dirname(__file__))

from config import OUTPUT_DIR, NUM_VIDEOS
from src.preprocessing.a_preprocessing      import run_preprocessing
from src.preprocessing.b_alignment          import run_alignment
from src.preprocessing.c_normalise_rotation import run_normalise_rotation
from src.features.hojo2d       import compute_hojo2d
from src.features.hojd2d       import compute_hojd2d
from src.features.fft_jo       import compute_fftjo
from src.features.fft_jd       import compute_fftjd
from src.features.ang_dis      import compute_angdis
from src.features.rel_jo       import compute_rel_jo
from src.features.rel_jo_angdis import compute_rel_jo_angdis


def main():
    t0 = time.time()
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("\n" + "="*60)
    print("  Cerebral Palsy RVI-38 — Feature Extraction Pipeline")
    print("="*60 + "\n")

    # ── STEP A: Pre-processing ──────────────────────────────────────────────
    print("[Step A] Pre-processing (load JSON, interpolate, smooth)...")
    all_pose = run_preprocessing(verbose=True)

    # ── STEP B: Alignment ───────────────────────────────────────────────────
    print("\n[Step B] Alignment (root-centre on midHip)...")
    align_results = run_alignment(all_pose, verbose=True)

    # ── STEP C: Normalise Rotation ──────────────────────────────────────────
    print("\n[Step C] Rotation normalisation (align spine to Y-axis)...")
    all_final_pose, parent_ids = run_normalise_rotation(align_results, verbose=True)

    # ── STEP D: Feature Extraction (7 types × 2 bin sizes = 14 files) ───────
    print("\n[Step D] Feature extraction (14 feature sets)...\n")

    # D1 — HOJO2D (Histogram of Joint Orientation)
    print("  -> HOJO2D 8-bin")
    hojo8  = compute_hojo2d(all_final_pose, parent_ids, num_bin=8)
    print("  -> HOJO2D 16-bin")
    hojo16 = compute_hojo2d(all_final_pose, parent_ids, num_bin=16)

    # D2 — HOJD2D (Histogram of Joint Displacement)
    print("  -> HOJD2D 8-bin")
    hojd8  = compute_hojd2d(all_final_pose, num_bin=8)
    print("  -> HOJD2D 16-bin")
    hojd16 = compute_hojd2d(all_final_pose, num_bin=16)

    # D3 — FFTJO (FFT of Joint Orientation)
    print("  -> FFTJO 8-bin")
    fftjo8  = compute_fftjo(all_final_pose, parent_ids, num_bin=8)
    print("  -> FFTJO 16-bin")
    fftjo16 = compute_fftjo(all_final_pose, parent_ids, num_bin=16)

    # D4 — FFTJD (FFT of Joint Displacement)
    print("  -> FFTJD 8-bin")
    fftjd8  = compute_fftjd(all_final_pose, num_bin=8)
    print("  -> FFTJD 16-bin")
    fftjd16 = compute_fftjd(all_final_pose, num_bin=16)

    # D5 — AngDis (Angular Displacement)
    print("  -> AngDis 8-bin")
    angdis8  = compute_angdis(all_final_pose, parent_ids, num_bin=8)
    print("  -> AngDis 16-bin")
    angdis16 = compute_angdis(all_final_pose, parent_ids, num_bin=16)

    # D6 — Rel_JO (Relative Joint Orientation)
    print("  -> Rel_JO 8-bin")
    reljo8  = compute_rel_jo(all_final_pose, num_bin=8)
    print("  -> Rel_JO 16-bin")
    reljo16 = compute_rel_jo(all_final_pose, num_bin=16)

    # D7 — Rel_JO_AngDis (Relative Joint Orientation + Angular Displacement)
    print("  -> Rel_JO_AngDis 8-bin")
    reljoad8  = compute_rel_jo_angdis(all_final_pose, num_bin=8)
    print("  -> Rel_JO_AngDis 16-bin")
    reljoad16 = compute_rel_jo_angdis(all_final_pose, num_bin=16)

    # ── Save all features to one .npz file ───────────────────────────────────
    print("\n[Save] Saving feature matrices to outputs/features/...")

    save_dict = {}

    # HOJO2D — store with suffix _hjo to distinguish from HOJD2D
    for k, v in hojo8.items():
        save_dict[f"hojo_{k}"] = v
    for k, v in hojo16.items():
        save_dict[f"hojo_{k}"] = v

    # HOJD2D
    for k, v in hojd8.items():
        save_dict[f"hojd_{k}"] = v
    for k, v in hojd16.items():
        save_dict[f"hojd_{k}"] = v

    # FFTJO
    for k, v in fftjo8.items():
        save_dict[f"fftjo_{k}"] = v
    for k, v in fftjo16.items():
        save_dict[f"fftjo_{k}"] = v

    # FFTJD
    for k, v in fftjd8.items():
        save_dict[f"fftjd_{k}"] = v
    for k, v in fftjd16.items():
        save_dict[f"fftjd_{k}"] = v

    # AngDis
    for k, v in angdis8.items():
        save_dict[f"angdis_{k}"] = v
    for k, v in angdis16.items():
        save_dict[f"angdis_{k}"] = v

    # Rel_JO
    for k, v in reljo8.items():
        save_dict[f"reljo_{k}"] = v
    for k, v in reljo16.items():
        save_dict[f"reljo_{k}"] = v

    # Rel_JO_AngDis
    for k, v in reljoad8.items():
        save_dict[f"reljoad_{k}"] = v
    for k, v in reljoad16.items():
        save_dict[f"reljoad_{k}"] = v

    out_path = os.path.join(OUTPUT_DIR, "RVI_38_features.npz")
    np.savez(out_path, **save_dict)

    elapsed = time.time() - t0
    print(f"\nDONE All features saved to: {out_path}")
    print(f"  Total arrays saved : {len(save_dict)}")
    print(f"  Total time         : {elapsed:.1f}s\n")

    # ── Summary table ────────────────────────────────────────────────────────
    print("  Feature shapes (n_videos × n_features):")
    print(f"  {'Name':<30} {'Shape'}")
    print(f"  {'-'*45}")
    for name, arr in sorted(save_dict.items()):
        print(f"  {name:<30} {arr.shape}")
    print()


if __name__ == "__main__":
    main()
