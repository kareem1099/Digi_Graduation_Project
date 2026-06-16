import sys, os
sys.path.insert(0, '.')

# Test all module imports
from config import PARENT_IDS
from src.preprocessing.a_preprocessing import preprocess_video
from src.preprocessing.b_alignment import align_video
from src.preprocessing.c_normalise_rotation import normalise_rotation_video
from src.features.utils import build_bin_vectors, build_ang_dis_bins
from src.features.hojo2d import compute_hojo2d
from src.features.hojd2d import compute_hojd2d
from src.features.fft_jo import compute_fftjo
from src.features.fft_jd import compute_fftjd
from src.features.ang_dis import compute_angdis
from src.features.rel_jo import compute_rel_jo
from src.features.rel_jo_angdis import compute_rel_jo_angdis
from src.classification.feature_fusion import build_feature_sets
from src.classification.classifier import run_loocv
import numpy as np

print("All imports OK")

# Helper function sanity checks
bv = build_bin_vectors(8)
assert bv.shape == (2, 8), "Expected (2,8) got {}".format(bv.shape)
ab = build_ang_dis_bins(8)
assert ab[-1] == 180.0
print("Bin helpers OK  | AngDis bins:", np.round(ab, 3))

# Preprocessing - video 1
print("\nTesting preprocessing on video 1...")
r = preprocess_video(1)
print("  n_frames:", r["n_frames"], "| pose shape:", r["pose"].shape)

ab_r = align_video(r["pose"])
print("  corrected_pose:", ab_r["corrected_pose"].shape)
print("  alignment_vec:", ab_r["alignment_vec"].shape)

pID = np.array(PARENT_IDS)
fp = normalise_rotation_video(ab_r["corrected_pose"], ab_r["alignment_vec"])
print("  final_pose:", fp.shape)

# Feature extraction on video 1 only
print("\nTesting all features on video 1...")
all_fp = {1: fp}

h8  = compute_hojo2d(all_fp, pID, num_bin=8, verbose=False)
print("  HOJO2D-8  RightElbow shape:", h8["RightElbow8"].shape)

d8  = compute_hojd2d(all_fp, num_bin=8, verbose=False)
print("  HOJD2D-8  RightElbow shape:", d8["RightElbow8"].shape)

fjo8 = compute_fftjo(all_fp, pID, num_bin=8, verbose=False)
print("  FFTJO-8   RightElbow shape:", fjo8["RightElbow8"].shape)

fjd8 = compute_fftjd(all_fp, num_bin=8, verbose=False)
print("  FFTJD-8   RightElbow shape:", fjd8["RightElbow8"].shape)

ang8 = compute_angdis(all_fp, pID, num_bin=8, verbose=False)
print("  AngDis-8  RightElbow shape:", ang8["RightElbow8"].shape)

rjo8 = compute_rel_jo(all_fp, num_bin=8, verbose=False)
print("  RelJO-8   Larm shape:", rjo8["Larm8"].shape)

rjad8 = compute_rel_jo_angdis(all_fp, num_bin=8, verbose=False)
print("  RelJOAD-8 Larm shape:", rjad8["Larm8"].shape)

print("\nAll smoke tests PASSED!")
