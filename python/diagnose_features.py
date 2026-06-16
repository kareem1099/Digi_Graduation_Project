"""
diagnose_features.py
---------------------
Inspect the saved feature matrices for anomalies:
  - Zero/constant columns
  - NaN/Inf values
  - Distribution per class
  - Label balance
"""
import os, sys
import numpy as np
import scipy.io

sys.path.insert(0, os.path.dirname(__file__))
from config import OUTPUT_DIR, LABELS_MAT
from run_classification import load_features
from src.classification.feature_fusion import build_feature_sets

# ── Load ─────────────────────────────────────────────────────────────────────
npz_path = os.path.join(OUTPUT_DIR, "RVI_38_features.npz")
feats = load_features(npz_path)
labels = scipy.io.loadmat(LABELS_MAT)["labels"].flatten().astype(int)

print("="*60)
print("  DIAGNOSTIC REPORT")
print("="*60)

# ── 1. Label distribution ────────────────────────────────────────────────────
n_cp = (labels == 1).sum()
n_healthy = (labels == 0).sum()
print(f"\n[Labels] Total={len(labels)}, CP={n_cp}, Healthy={n_healthy}")
print(f"         CP ratio={n_cp/len(labels)*100:.1f}%  (majority-class baseline = {n_healthy/len(labels)*100:.1f}%)")
print(f"         CP indices: {np.where(labels==1)[0].tolist()}")

# ── 2. Per-feature-array diagnostics ─────────────────────────────────────────
print(f"\n[Raw Features] {len(feats)} arrays loaded")
print(f"  {'Key':<30} {'Shape':<15} {'NaN?':>5} {'Inf?':>5} {'AllZeroRows':>12} {'ConstCols':>10} {'MinVal':>8} {'MaxVal':>8}")
print(f"  {'-'*98}")

problem_keys = []
for key in sorted(feats.keys()):
    arr = feats[key]
    has_nan = np.any(np.isnan(arr))
    has_inf = np.any(np.isinf(arr))
    zero_rows = np.sum(np.all(arr == 0, axis=1)) if arr.ndim == 2 else 0
    const_cols = np.sum(np.std(arr, axis=0) == 0) if arr.ndim == 2 else 0
    mn, mx = arr.min(), arr.max()
    flag = ""
    if has_nan or has_inf or (arr.ndim == 2 and zero_rows > len(labels)//2):
        flag = " *** PROBLEM"
        problem_keys.append(key)
    print(f"  {key:<30} {str(arr.shape):<15} {str(has_nan):>5} {str(has_inf):>5} {zero_rows:>12} {const_cols:>10} {mn:>8.4f} {mx:>8.4f}{flag}")

# ── 3. Fusion matrix diagnostics ─────────────────────────────────────────────
print(f"\n[Fusion Matrices]")
sets = build_feature_sets(feats)

for name in ["PoseVelFusion", "PoseFusion", "VelFusion"]:
    X = sets[name]
    print(f"\n  {name}: shape={X.shape}")
    
    # Check constant columns
    stds = np.std(X, axis=0)
    n_const = np.sum(stds == 0)
    n_near_const = np.sum(stds < 1e-6)
    print(f"    Constant columns (std=0): {n_const}/{X.shape[1]}")
    print(f"    Near-constant columns (std<1e-6): {n_near_const}/{X.shape[1]}")
    
    # Check NaN/Inf
    print(f"    NaN count: {np.sum(np.isnan(X))},  Inf count: {np.sum(np.isinf(X))}")
    
    # Per-class stats
    cp_mask = labels == 1
    h_mask = labels == 0
    cp_mean = X[cp_mask].mean(axis=0)
    h_mean = X[h_mask].mean(axis=0)
    diff = np.abs(cp_mean - h_mean)
    
    print(f"    Features with |mean_CP - mean_Healthy| > 0.05: {np.sum(diff > 0.05)}/{X.shape[1]}")
    print(f"    Features with |mean_CP - mean_Healthy| > 0.10: {np.sum(diff > 0.10)}/{X.shape[1]}")
    
    # Top discriminative features
    if np.sum(diff > 0) > 0:
        top_idx = np.argsort(diff)[::-1][:10]
        print(f"    Top 10 most discriminative feature indices: {top_idx.tolist()}")
        print(f"    Top 10 mean-diffs: {[f'{diff[i]:.4f}' for i in top_idx]}")

    # Zero rows (videos with all-zero feature vectors)
    zero_vids = np.where(np.all(X == 0, axis=1))[0]
    if len(zero_vids) > 0:
        print(f"    *** VIDEOS WITH ALL-ZERO FEATURES: {zero_vids.tolist()}")

print("\n" + "="*60)
if problem_keys:
    print(f"  PROBLEMS FOUND in: {problem_keys}")
else:
    print("  No critical anomalies detected in raw features.")
print("="*60)
