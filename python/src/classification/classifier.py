"""
classifier.py
--------------
Leave-One-Out Cross-Validation (LOOCV) with 7 classifiers and full metrics.

Matches B_Classification_RVI.m exactly:
  - Z-score normalisation computed on ALL samples (including test), then test
    removed after stats computed (matches MATLAB's 'pre-remove' zscore).
  - 7 classifiers: SVM, Decision Tree, 1-NN, 3-NN, LDA, Ensemble, LogReg.
  - Metrics: Accuracy, Sensitivity, Specificity, F1, MCC.
"""

import numpy as np
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))
from config import ENSEMBLE_N_CYCLES, ENSEMBLE_LEARN_RATE, ENSEMBLE_MIN_LEAF


# ── Metric helpers ─────────────────────────────────────────────────────────────

def _get_tp(pred, gt):
    """True positives: pred=1 AND gt=1  →  pred + gt*2 == 3"""
    return int(np.sum((pred + gt * 2) == 3))

def _get_tn(pred, gt):
    """True negatives: pred=0 AND gt=0  →  pred + gt*2 == 0"""
    return int(np.sum((pred + gt * 2) == 0))

def _get_fp(pred, gt):
    """False positives: pred=1 AND gt=0  →  pred + gt*2 == 1"""
    return int(np.sum((pred + gt * 2) == 1))

def _get_fn(pred, gt):
    """False negatives: pred=0 AND gt=1  →  pred + gt*2 == 2"""
    return int(np.sum((pred + gt * 2) == 2))


def compute_metrics(pred_lbl: np.ndarray, gt_lbl: np.ndarray,
                    n_correct: int, n_total: int) -> dict:
    """
    Compute Accuracy, Sensitivity, Specificity, F1, and MCC.
    Returns a dict. All percentage values (0–100 scale).
    """
    TP = _get_tp(pred_lbl, gt_lbl)
    TN = _get_tn(pred_lbl, gt_lbl)
    FP = _get_fp(pred_lbl, gt_lbl)
    FN = _get_fn(pred_lbl, gt_lbl)

    accuracy    = (n_correct / n_total) * 100
    sensitivity = (TP / (TP + FN) * 100) if (TP + FN) > 0 else 0.0
    specificity = (TN / (TN + FP) * 100) if (TN + FP) > 0 else 0.0
    precision   = (TP / (TP + FP) * 100) if (TP + FP) > 0 else 0.0
    recall      = sensitivity
    f1          = (2 * precision * recall / (precision + recall)
                   if (precision + recall) > 0 else 0.0)
    denom = ((TP + FP) * (TP + FN) * (TN + FP) * (TN + FN))
    mcc   = ((TP * TN - FP * FN) / (denom ** 0.5) * 100
             if denom > 0 else 0.0)

    return dict(accuracy=accuracy, sensitivity=sensitivity,
                specificity=specificity, f1=f1, mcc=mcc,
                TP=TP, TN=TN, FP=FP, FN=FN)


# ── LOOCV ──────────────────────────────────────────────────────────────────────

def run_loocv(X: np.ndarray, y: np.ndarray,
              verbose: bool = True) -> dict:
    """
    Leave-One-Out Cross-Validation with 7 classifiers.

    Normalisation note (mirrors MATLAB):
      zscore stats are computed on the FULL X (including the test sample),
      then the test row is removed from training. This is a faithful
      replication of the original MATLAB code.

    Parameters
    ----------
    X : (n_samples, n_features)
    y : (n_samples,)  — binary labels: 0=healthy, 1=CP

    Returns
    -------
    results : dict — metrics per classifier
    """
    n = len(y)
    y = y.astype(int)

    # Prediction label arrays
    svm_pred   = np.zeros(n, dtype=int)
    tree_pred  = np.zeros(n, dtype=int)
    nn1_pred   = np.zeros(n, dtype=int)
    nn3_pred   = np.zeros(n, dtype=int)
    lda_pred   = np.zeros(n, dtype=int)
    ens_pred   = np.zeros(n, dtype=int)
    lr_pred    = np.zeros(n, dtype=int)

    # Accuracy counters
    svm_acc = tree_acc = nn1_acc = nn3_acc = 0
    lda_acc = ens_acc  = lr_acc  = 0

    for i in range(n):
        if verbose:
            print(f"    LOOCV fold {i+1:02d}/{n}...", end="\r")

        # ── Normalisation (includes test sample, then remove) ──
        mu    = X.mean(axis=0)
        sigma = X.std(axis=0, ddof=1)      # MATLAB zscore uses ddof=1
        sigma[sigma == 0] = 1.0

        test_x  = (X[i] - mu) / sigma
        mask    = np.ones(n, dtype=bool)
        mask[i] = False
        train_X = (X[mask] - mu) / sigma
        train_y = y[mask]

        test_x = test_x.reshape(1, -1)
        true_y = int(y[i])

        # ── SVM ──────────────────────────────────────────────
        clf = SVC(kernel="rbf")
        clf.fit(train_X, train_y)
        p = int(clf.predict(test_x)[0])
        svm_pred[i] = p
        svm_acc    += (1 if p == true_y else 0)

        # ── Decision Tree ─────────────────────────────────────
        clf = DecisionTreeClassifier()
        clf.fit(train_X, train_y)
        p = int(clf.predict(test_x)[0])
        tree_pred[i] = p
        tree_acc    += (1 if p == true_y else 0)

        # ── 1-NN ──────────────────────────────────────────────
        clf = KNeighborsClassifier(n_neighbors=1)
        clf.fit(train_X, train_y)
        p = int(clf.predict(test_x)[0])
        nn1_pred[i] = p
        nn1_acc    += (1 if p == true_y else 0)

        # ── 3-NN ──────────────────────────────────────────────
        clf = KNeighborsClassifier(n_neighbors=3)
        clf.fit(train_X, train_y)
        p = int(clf.predict(test_x)[0])
        nn3_pred[i] = p
        nn3_acc    += (1 if p == true_y else 0)

        # ── LDA (pseudo-linear) ────────────────────────────────
        clf = LinearDiscriminantAnalysis(solver="lsqr", shrinkage="auto")
        clf.fit(train_X, train_y)
        p = int(clf.predict(test_x)[0])
        lda_pred[i] = p
        lda_acc    += (1 if p == true_y else 0)

        # ── Ensemble (LogitBoost) ──────────────────────────────
        clf = GradientBoostingClassifier(
            n_estimators    = ENSEMBLE_N_CYCLES,
            learning_rate   = ENSEMBLE_LEARN_RATE,
            max_leaf_nodes  = ENSEMBLE_MIN_LEAF + 1,   # MinLeafSize≈MaxLeafNodes
            max_depth       = 1,                        # MaxNumSplits=2 → depth=1
        )
        clf.fit(train_X, train_y)
        p = int(clf.predict(test_x)[0])
        ens_pred[i] = p
        ens_acc    += (1 if p == true_y else 0)

        # ── Logistic Regression ────────────────────────────────
        clf = LogisticRegression(
            class_weight = "balanced",   # 'prior','uniform' → balanced
            max_iter     = 1000,
            solver       = "lbfgs",
        )
        clf.fit(train_X, train_y)
        p = int(clf.predict(test_x)[0])
        lr_pred[i] = p
        lr_acc    += (1 if p == true_y else 0)

    if verbose:
        print(f"    LOOCV complete ({n} folds).              ")

    # ── Compute metrics for each classifier ──────────────────────────────────
    return {
        "SVM":      compute_metrics(svm_pred,  y, svm_acc,  n),
        "Tree":     compute_metrics(tree_pred, y, tree_acc, n),
        "NN1":      compute_metrics(nn1_pred,  y, nn1_acc,  n),
        "NN3":      compute_metrics(nn3_pred,  y, nn3_acc,  n),
        "LDA":      compute_metrics(lda_pred,  y, lda_acc,  n),
        "Ensemble": compute_metrics(ens_pred,  y, ens_acc,  n),
        "LogReg":   compute_metrics(lr_pred,   y, lr_acc,   n),
    }


def print_results(label: str, results: dict) -> None:
    """Pretty-print classification results for all classifiers."""
    print(f"\n{'='*60}")
    print(f"  Feature Set: {label}")
    print(f"{'='*60}")
    fmt = "  {:<10}  Acc={:5.1f}%  Sens={:5.1f}%  Spec={:5.1f}%  F1={:5.1f}  MCC={:5.1f}"
    for clf_name, m in results.items():
        print(fmt.format(
            clf_name,
            m["accuracy"], m["sensitivity"], m["specificity"],
            m["f1"], m["mcc"]
        ))
    print()
