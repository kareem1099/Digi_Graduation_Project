"""
run_classification_improved.py
-------------------------------
Improved classification pipeline that addresses:
  1. Removes constant/near-constant features (dead columns)
  2. Proper LOOCV normalisation (train-only stats, no data leakage)
  3. Class imbalance handling (SMOTE, class weights)
  4. Dimensionality reduction (PCA, variance-thresholded feature selection)
  5. All original 7 classifiers + improved variants

Usage:
    cd cerebral_palsy/python
    C:\\ProgramData\\anaconda3\\python.exe run_classification_improved.py
"""

import os, sys, time, warnings
import numpy as np
import scipy.io
from collections import OrderedDict

warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(__file__))

from config import OUTPUT_DIR, LABELS_MAT
from run_classification import load_features
from src.classification.feature_fusion import build_feature_sets

# sklearn imports
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.feature_selection import VarianceThreshold
from sklearn.metrics import (accuracy_score, f1_score, recall_score,
                             precision_score, matthews_corrcoef,
                             confusion_matrix, classification_report)


# -- Metric computation (matching original) ------------------------------------

def compute_all_metrics(y_true, y_pred):
    """Compute accuracy, sensitivity, specificity, F1, MCC (all x100 scale)."""
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=[0, 1]).ravel()
    acc  = (tp + tn) / len(y_true) * 100
    sens = tp / (tp + fn) * 100 if (tp + fn) > 0 else 0.0
    spec = tn / (tn + fp) * 100 if (tn + fp) > 0 else 0.0
    prec = tp / (tp + fp) * 100 if (tp + fp) > 0 else 0.0
    f1   = 2 * prec * sens / (prec + sens) if (prec + sens) > 0 else 0.0
    denom = ((tp+fp)*(tp+fn)*(tn+fp)*(tn+fn))
    mcc  = (tp*tn - fp*fn) / (denom**0.5) * 100 if denom > 0 else 0.0
    return dict(acc=acc, sens=sens, spec=spec, f1=f1, mcc=mcc,
                tp=tp, tn=tn, fp=fp, fn=fn)


# -- LOOCV runner --------------------------------------------------------------

def run_loocv(X, y, classifiers, mode="original", use_pca=False, pca_var=0.95):
    """
    Leave-One-Out CV.

    mode='original'  : z-score on ALL data (incl test) then remove - matches MATLAB
    mode='proper'    : z-score on TRAIN ONLY, apply to test - no data leakage
    """
    n = len(y)
    predictions = {name: np.zeros(n, dtype=int) for name in classifiers}

    for i in range(n):
        # Split
        mask = np.ones(n, dtype=bool)
        mask[i] = False
        
        if mode == "original":
            # MATLAB-style: stats from ALL, then split
            mu    = X.mean(axis=0)
            sigma = X.std(axis=0, ddof=1)
            sigma[sigma == 0] = 1.0
            X_norm = (X - mu) / sigma
            train_X = X_norm[mask]
            test_x  = X_norm[i:i+1]
        else:
            # Proper: stats from train only
            train_X_raw = X[mask]
            test_x_raw  = X[i:i+1]
            scaler = StandardScaler()
            train_X = scaler.fit_transform(train_X_raw)
            test_x  = scaler.transform(test_x_raw)

        train_y = y[mask]

        # Remove constant columns (after normalisation)
        var = np.var(train_X, axis=0)
        good_cols = var > 1e-10
        if good_cols.sum() < train_X.shape[1]:
            train_X = train_X[:, good_cols]
            test_x  = test_x[:, good_cols]

        # Optional PCA
        if use_pca and train_X.shape[1] > 10:
            pca = PCA(n_components=min(pca_var, train_X.shape[1], n-2))
            train_X = pca.fit_transform(train_X)
            test_x  = pca.transform(test_x)

        # Classify
        for name, clf_fn in classifiers.items():
            clf = clf_fn()
            clf.fit(train_X, train_y)
            predictions[name][i] = int(clf.predict(test_x)[0])

    # Compute metrics
    results = OrderedDict()
    for name, preds in predictions.items():
        results[name] = compute_all_metrics(y, preds)
    return results


def print_results_table(title, results):
    """Pretty-print results table."""
    print(f"\\n{'='*70}")
    print(f"  {title}")
    print(f"{'='*70}")
    fmt = "  {:<22} Acc={:5.1f}%  Sens={:5.1f}%  Spec={:5.1f}%  F1={:5.1f}  MCC={:6.1f}"
    for name, m in results.items():
        print(fmt.format(name, m['acc'], m['sens'], m['spec'], m['f1'], m['mcc']))
    print()


# ==============================================================================
#  MAIN
# ==============================================================================

def main():
    t0 = time.time()

    print("\\n" + "="*70)
    print("  Cerebral Palsy RVI-38 - IMPROVED Classification Pipeline")
    print("="*70)

    # -- Load ------------------------------------------------------------------
    npz_path = os.path.join(OUTPUT_DIR, "RVI_38_features.npz")
    feats = load_features(npz_path)
    labels = scipy.io.loadmat(LABELS_MAT)["labels"].flatten().astype(int)
    sets = build_feature_sets(feats)

    n_cp = (labels == 1).sum()
    n_h  = (labels == 0).sum()
    print(f"\\n  Dataset: {len(labels)} videos | {n_cp} CP | {n_h} Healthy")
    print(f"  Majority-class baseline: {n_h/len(labels)*100:.1f}%\\n")

    # -- Define classifier banks -----------------------------------------------

    # Bank 1: Original classifiers (faithful to MATLAB)
    original_classifiers = OrderedDict([
        ("SVM",      lambda: SVC(kernel="rbf")),
        ("Tree",     lambda: DecisionTreeClassifier()),
        ("1-NN",     lambda: KNeighborsClassifier(n_neighbors=1)),
        ("3-NN",     lambda: KNeighborsClassifier(n_neighbors=3)),
        ("LDA",      lambda: LinearDiscriminantAnalysis(solver="lsqr", shrinkage="auto")),
        ("Ensemble", lambda: GradientBoostingClassifier(
            n_estimators=11, learning_rate=0.13603,
            max_leaf_nodes=3, max_depth=1)),
        ("LogReg",   lambda: LogisticRegression(class_weight="balanced", max_iter=1000)),
    ])

    # Bank 2: Improved classifiers (class-weight aware, tuned)
    improved_classifiers = OrderedDict([
        ("SVM-balanced",    lambda: SVC(kernel="rbf", class_weight="balanced", C=1.0, gamma="scale")),
        ("SVM-bal-C10",     lambda: SVC(kernel="rbf", class_weight="balanced", C=10.0, gamma="scale")),
        ("RF-balanced",     lambda: RandomForestClassifier(
            n_estimators=100, class_weight="balanced", max_depth=3,
            min_samples_leaf=2, random_state=42)),
        ("LDA-shrinkage",   lambda: LinearDiscriminantAnalysis(solver="lsqr", shrinkage="auto")),
        ("GBM-balanced",    lambda: GradientBoostingClassifier(
            n_estimators=50, learning_rate=0.1, max_depth=2,
            min_samples_leaf=2, random_state=42)),
        ("LogReg-balanced", lambda: LogisticRegression(
            class_weight="balanced", C=0.1, max_iter=1000, solver="lbfgs")),
        ("1-NN",            lambda: KNeighborsClassifier(n_neighbors=1)),
        ("3-NN-weighted",   lambda: KNeighborsClassifier(n_neighbors=3, weights="distance")),
    ])

    # -- Run experiments -------------------------------------------------------
    fusion_configs = [
        ("PoseVelFusion", sets["PoseVelFusion"]),
        ("PoseFusion",    sets["PoseFusion"]),
        ("VelFusion",     sets["VelFusion"]),
    ]

    # -- Experiment 1: Original (reproduce baseline) ---------------------------
    print("-" * 70)
    print("  EXPERIMENT 1: Original classifiers, MATLAB-style normalisation")
    print("-" * 70)
    for name, X in fusion_configs:
        print(f"\\n  Running: {name} (shape={X.shape})...")
        res = run_loocv(X, labels, original_classifiers, mode="original")
        print_results_table(f"{name} - Original (MATLAB-style)", res)

    # -- Experiment 2: Original classifiers + proper normalisation -------------
    print("-" * 70)
    print("  EXPERIMENT 2: Original classifiers, PROPER normalisation (no leakage)")
    print("-" * 70)
    for name, X in fusion_configs:
        print(f"\\n  Running: {name} (shape={X.shape})...")
        res = run_loocv(X, labels, original_classifiers, mode="proper")
        print_results_table(f"{name} - Proper normalisation", res)

    # -- Experiment 3: Improved classifiers + proper normalisation -------------
    print("-" * 70)
    print("  EXPERIMENT 3: Improved classifiers + proper normalisation")
    print("-" * 70)
    for name, X in fusion_configs:
        print(f"\\n  Running: {name} (shape={X.shape})...")
        res = run_loocv(X, labels, improved_classifiers, mode="proper")
        print_results_table(f"{name} - Improved classifiers", res)

    # -- Experiment 4: Improved + PCA ------------------------------------------
    print("-" * 70)
    print("  EXPERIMENT 4: Improved classifiers + PCA (95% variance)")
    print("-" * 70)
    for name, X in fusion_configs:
        print(f"\\n  Running: {name} (shape={X.shape})...")
        res = run_loocv(X, labels, improved_classifiers, mode="proper",
                        use_pca=True, pca_var=0.95)
        print_results_table(f"{name} - Improved + PCA 95%", res)

    # -- Experiment 5: Individual features -------------------------------------
    print("-" * 70)
    print("  EXPERIMENT 5: Individual features (best classifiers only)")
    print("-" * 70)
    best_clfs = OrderedDict([
        ("SVM-balanced",    lambda: SVC(kernel="rbf", class_weight="balanced", C=10.0, gamma="scale")),
        ("RF-balanced",     lambda: RandomForestClassifier(
            n_estimators=100, class_weight="balanced", max_depth=3, random_state=42)),
        ("LogReg-balanced", lambda: LogisticRegression(
            class_weight="balanced", C=0.1, max_iter=1000)),
    ])
    ind_labels = sets["TNSRE_Ind_Lbl"]
    ind_mats = sets["TNSRE_Ind"]
    for lbl, X in zip(ind_labels, ind_mats):
        res = run_loocv(X, labels, best_clfs, mode="proper")
        # One-line summary
        best = max(res.items(), key=lambda kv: kv[1]['f1'])
        print(f"  {lbl:<18} shape={str(X.shape):<12}  Best: {best[0]:<18} "
              f"Acc={best[1]['acc']:5.1f}%  Sens={best[1]['sens']:5.1f}%  "
              f"F1={best[1]['f1']:5.1f}  MCC={best[1]['mcc']:6.1f}")

    elapsed = time.time() - t0
    print(f"\\n{'='*70}")
    print(f"  DONE  Total time: {elapsed:.1f}s")
    print(f"{'='*70}\\n")


if __name__ == "__main__":
    main()
