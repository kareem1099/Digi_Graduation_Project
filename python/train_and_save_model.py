"""
train_and_save_model.py
-----------------------
Trains the final model on the entire RVI-38 dataset and saves it to disk.
We use LogisticRegression(class_weight='balanced') on the PoseVelFusion
feature set, which provides robust performance and outputs probabilities
so we can adjust the sensitivity threshold in the UI.
"""

import os, sys, joblib
import numpy as np
import scipy.io

sys.path.insert(0, os.path.dirname(__file__))

from config import OUTPUT_DIR, LABELS_MAT
from run_classification import load_features
from src.classification.feature_fusion import build_feature_sets
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

def main():
    print("="*60)
    print(" Training Final Model ")
    print("="*60)
    
    models_dir = os.path.join(os.path.dirname(__file__), "saved_models")
    os.makedirs(models_dir, exist_ok=True)
    
    # 1. Load data
    npz_path = os.path.join(OUTPUT_DIR, "RVI_38_features.npz")
    if not os.path.exists(npz_path):
        print(f"Error: {npz_path} not found.")
        return
        
    feats = load_features(npz_path)
    labels = scipy.io.loadmat(LABELS_MAT)["labels"].flatten().astype(int)
    sets = build_feature_sets(feats)
    
    # We will use PoseVelFusion (the full feature set)
    X = sets["PoseVelFusion"]
    y = labels
    
    print(f"Dataset shape: {X.shape}")
    print(f"Labels: {np.sum(y==1)} CP, {np.sum(y==0)} Healthy")
    
    # 2. Filter out constant features (noise)
    var = np.var(X, axis=0)
    good_cols = var > 1e-10
    X_clean = X[:, good_cols]
    print(f"Removed {X.shape[1] - X_clean.shape[1]} constant columns. Remaining: {X_clean.shape[1]}")
    
    # 3. Fit Scaler
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_clean)
    
    # 4. Train Model
    # Logistic Regression with balanced class weights ensures the model 
    # pays extra attention to the minority CP class (highest sensitivity).
    clf = LogisticRegression(class_weight="balanced", C=0.1, max_iter=1000, solver="lbfgs")
    clf.fit(X_scaled, y)
    
    train_acc = clf.score(X_scaled, y)
    print(f"Training Accuracy: {train_acc*100:.1f}%")
    
    # 5. Save Pipeline components
    pipeline = {
        "scaler": scaler,
        "classifier": clf,
        "good_cols": good_cols
    }
    
    model_path = os.path.join(models_dir, "cp_model.pkl")
    joblib.dump(pipeline, model_path)
    print(f"Model saved successfully to: {model_path}")
    print("="*60)

if __name__ == "__main__":
    main()
