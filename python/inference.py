"""
inference.py
------------
End-to-end inference script for raw video input using MediaPipe Pose.
Maps MediaPipe keypoints to OpenPose BODY_25 format, runs the CP extraction
pipeline, and predicts using the trained Logistic Regression model.
"""

import os
import sys
import cv2
import numpy as np
import joblib
import mediapipe as mp
import warnings

warnings.filterwarnings("ignore")
sys.path.insert(0, os.path.dirname(__file__))

from config import JOINT_RANGE, CONFIDENCE_MARGIN, SMOOTH_WINDOW
from src.preprocessing.a_preprocessing import _moving_average
from src.preprocessing.b_alignment import run_alignment
from src.preprocessing.c_normalise_rotation import run_normalise_rotation

from src.features.hojo2d import compute_hojo2d
from src.features.hojd2d import compute_hojd2d
from src.features.fft_jo import compute_fftjo
from src.features.fft_jd import compute_fftjd
from src.features.ang_dis import compute_angdis
from src.features.rel_jo import compute_rel_jo
from src.features.rel_jo_angdis import compute_rel_jo_angdis

from scipy.interpolate import Akima1DInterpolator

import urllib.request
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

# Download model if not exists
mp_model_path = os.path.join(os.path.dirname(__file__), "pose_landmarker.task")
if not os.path.exists(mp_model_path):
    print("Downloading MediaPipe Pose model...")
    url = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task"
    urllib.request.urlretrieve(url, mp_model_path)

def map_mediapipe_to_openpose(landmarks, w, h):
    kp = np.zeros((25, 3))
    
    if not landmarks:
        return kp
        
    lm = landmarks # In new API, this is a list of NormalizedLandmark objects
    
    def set_kp(op_idx, mp_idx):
        kp[op_idx] = [lm[mp_idx].x * w, lm[mp_idx].y * h, lm[mp_idx].visibility]
        
    def avg_kp(op_idx, mp_idx1, mp_idx2):
        x = (lm[mp_idx1].x + lm[mp_idx2].x) / 2 * w
        y = (lm[mp_idx1].y + lm[mp_idx2].y) / 2 * h
        v = (lm[mp_idx1].visibility + lm[mp_idx2].visibility) / 2
        kp[op_idx] = [x, y, v]

    # Map directly
    set_kp(0, 0)   # Nose
    set_kp(2, 12)  # RShoulder
    set_kp(3, 14)  # RElbow
    set_kp(4, 16)  # RWrist
    set_kp(5, 11)  # LShoulder
    set_kp(6, 13)  # LElbow
    set_kp(7, 15)  # LWrist
    set_kp(9, 24)  # RHip
    set_kp(10, 26) # RKnee
    set_kp(11, 28) # RAnkle
    set_kp(12, 23) # LHip
    set_kp(13, 25) # LKnee
    set_kp(14, 27) # LAnkle
    set_kp(15, 5)  # REye
    set_kp(16, 2)  # LEye
    set_kp(17, 8)  # REar
    set_kp(18, 7)  # LEar
    set_kp(19, 31) # LBigToe (using MP foot index)
    set_kp(20, 31) # LSmallToe
    set_kp(21, 29) # LHeel
    set_kp(22, 32) # RBigToe
    set_kp(23, 32) # RSmallToe
    set_kp(24, 30) # RHeel
    
    # Computed joints
    avg_kp(1, 11, 12) # Neck = (LShoulder + RShoulder)/2
    avg_kp(8, 23, 24) # MidHip = (LHip + RHip)/2
    
    return kp

def extract_poses_from_video(video_path):
    cap = cv2.VideoCapture(video_path)
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    
    frames = []
    
    base_options = python.BaseOptions(model_asset_path=mp_model_path)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        output_segmentation_masks=False)
    
    with vision.PoseLandmarker.create_from_options(options) as detector:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
            
            detection_result = detector.detect(mp_image)
            if detection_result.pose_landmarks:
                # detection_result.pose_landmarks is a list of poses. Since 1 person, use [0]
                kp = map_mediapipe_to_openpose(detection_result.pose_landmarks[0], w, h)
                frames.append(kp)
            else:
                frames.append(np.zeros((25, 3)))
            
    cap.release()
    return np.stack(frames, axis=0) # (n_frames, 25, 3)

def preprocess_frames(all_kp):
    n_frames = all_kp.shape[0]
    idx = np.arange(0, n_frames)
    processed = np.zeros((n_frames, 21, 3))

    for out_j, orig_j in enumerate(JOINT_RANGE):
        confi = all_kp[:, orig_j, 2]
        x_raw = all_kp[:, orig_j, 0]
        y_raw = all_kp[:, orig_j, 1]

        mean_conf = float(np.mean(confi)) if len(confi) > 0 else 0
        good_mask = confi >= (mean_conf - CONFIDENCE_MARGIN)
        
        # Fallback if no frames are 'good'
        if not np.any(good_mask):
            good_mask = np.ones(n_frames, dtype=bool)

        good_idx  = idx[good_mask]
        good_x    = x_raw[good_mask]
        good_y    = y_raw[good_mask]

        if len(good_idx) < 2:
            # Not enough points to interpolate, keep raw
            processed[:, out_j, 0] = x_raw
            processed[:, out_j, 1] = y_raw
            processed[:, out_j, 2] = confi
            continue

        try:
            akima_x = Akima1DInterpolator(good_idx, good_x)
            akima_y = Akima1DInterpolator(good_idx, good_y)
            interp_x = akima_x(idx)
            interp_y = akima_y(idx)
        except ValueError:
            # Fallback to linear if Akima fails (e.g. not enough unique points)
            interp_x = np.interp(idx, good_idx, good_x)
            interp_y = np.interp(idx, good_idx, good_y)

        # Handle NaNs from extrapolation
        mask_nan_x = np.isnan(interp_x)
        if np.any(mask_nan_x):
            interp_x[mask_nan_x] = np.interp(idx[mask_nan_x], good_idx, good_x)
            interp_y[mask_nan_x] = np.interp(idx[mask_nan_x], good_idx, good_y)

        processed[:, out_j, 0] = _moving_average(interp_x, SMOOTH_WINDOW)
        processed[:, out_j, 1] = _moving_average(interp_y, SMOOTH_WINDOW)
        processed[:, out_j, 2] = confi

    return {
        "pose": processed,
        "n_frames": n_frames
    }

def extract_features(pose_dict):
    """Run extraction on a single video dict"""
    all_pose = {0: pose_dict}
    
    # Step B: Alignment
    align_results = run_alignment(all_pose, verbose=False)
    
    # Step C: Rotation
    final_pose, parent_ids = run_normalise_rotation(align_results, verbose=False)
    
    # Step D: Features
    feats = {}
    
    # Helper to merge 0-index dicts
    def merge(prefix, res1, res2):
        for k, v in res1.items(): feats[f"{k}8{prefix}"] = v[0]
        for k, v in res2.items(): feats[f"{k}16{prefix}"] = v[0]
        
    res8  = compute_hojo2d(final_pose, parent_ids, num_bin=8)
    res16 = compute_hojo2d(final_pose, parent_ids, num_bin=16)
    merge("", res8, res16)
    
    res8  = compute_hojd2d(final_pose, num_bin=8)
    res16 = compute_hojd2d(final_pose, num_bin=16)
    merge("_d", res8, res16)
    
    res8  = compute_fftjo(final_pose, parent_ids, num_bin=8)
    res16 = compute_fftjo(final_pose, parent_ids, num_bin=16)
    merge("_fjo", res8, res16)
    
    res8  = compute_fftjd(final_pose, num_bin=8)
    res16 = compute_fftjd(final_pose, num_bin=16)
    merge("_fjd", res8, res16)
    
    res8  = compute_angdis(final_pose, num_bin=8)
    res16 = compute_angdis(final_pose, num_bin=16)
    merge("_ang", res8, res16)
    
    res8  = compute_rel_jo(final_pose, num_bin=8)
    res16 = compute_rel_jo(final_pose, num_bin=16)
    merge("_rjo", res8, res16)
    
    res8  = compute_rel_jo_angdis(final_pose, num_bin=8)
    res16 = compute_rel_jo_angdis(final_pose, num_bin=16)
    merge("_rjad", res8, res16)
    
    # Build PoseVelFusion
    # TNSRE_PoseVel_Fusion = {[G16_Ind B16_Ind D16_Ind A8_Ind H8_Ind C16_Ind I8_Ind]}
    vector_parts = [
        # G16 (AngDisp_16)
        [feats["LeftWrist16_ang"], feats["LeftElbow16_ang"], feats["LeftKnee16_ang"], feats["LeftAnkle16_ang"],
         feats["RightWrist16_ang"], feats["RightElbow16_ang"], feats["RightKnee16_ang"], feats["RightAnkle16_ang"]],
         
        # B16 (HOJD2D_16)
        [feats["LeftWrist16_d"], feats["LeftElbow16_d"], feats["LeftKnee16_d"], feats["LeftAnkle16_d"],
         feats["RightWrist16_d"], feats["RightElbow16_d"], feats["RightKnee16_d"], feats["RightAnkle16_d"]],
         
        # D16 (FFTJD_16)
        [feats["LeftWrist16_fjd"], feats["LeftElbow16_fjd"], feats["LeftKnee16_fjd"], feats["LeftAnkle16_fjd"],
         feats["RightWrist16_fjd"], feats["RightElbow16_fjd"], feats["RightKnee16_fjd"], feats["RightAnkle16_fjd"]],
         
        # A8 (HOJO2D_8 added pairs)
        [feats["LeftWrist8"] + feats["LeftElbow8"], feats["LeftKnee8"] + feats["LeftAnkle8"],
         feats["RightWrist8"] + feats["RightElbow8"], feats["RightKnee8"] + feats["RightAnkle8"]],
         
        # H8 (Rel_JO_8)
        [feats["Larm8_rjo"], feats["Lleg8_rjo"], feats["Rarm8_rjo"], feats["Rleg8_rjo"]],
        
        # C16 (FFTJO_16)
        [feats["LeftWrist16_fjo"], feats["LeftElbow16_fjo"], feats["LeftKnee16_fjo"], feats["LeftAnkle16_fjo"],
         feats["RightWrist16_fjo"], feats["RightElbow16_fjo"], feats["RightKnee16_fjo"], feats["RightAnkle16_fjo"]],
         
        # I8 (Rel_JO_AngDis_8)
        [feats["Larm8_rjad"], feats["Lleg8_rjad"], feats["Rarm8_rjad"], feats["Rleg8_rjad"]]
    ]
    
    # Flatten the parts
    fusion_vec = []
    for part in vector_parts:
        for arr in part:
            fusion_vec.extend(arr.tolist())
            
    return np.array([fusion_vec]) # (1, 608)

def predict_video(video_path):
    print(f"Loading model...")
    model_path = os.path.join(os.path.dirname(__file__), "saved_models", "cp_model.pkl")
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model not found at {model_path}. Run train_and_save_model.py first.")
        
    pipeline = joblib.load(model_path)
    scaler = pipeline["scaler"]
    clf = pipeline["classifier"]
    good_cols = pipeline["good_cols"]
    
    print("Extracting poses from video using MediaPipe...")
    all_kp = extract_poses_from_video(video_path)
    if len(all_kp) < 10:
        raise ValueError("Video is too short or no poses detected.")
        
    print(f"Extracted {len(all_kp)} frames. Preprocessing...")
    pose_dict = preprocess_frames(all_kp)
    
    print("Extracting features...")
    X_fusion = extract_features(pose_dict)
    
    print("Running classification...")
    X_clean = X_fusion[:, good_cols]
    X_scaled = scaler.transform(X_clean)
    
    prob = clf.predict_proba(X_scaled)[0] # [Prob Healthy, Prob CP]
    pred = clf.predict(X_scaled)[0]
    
    return {
        "prediction": "Cerebral Palsy" if pred == 1 else "Healthy",
        "confidence_cp": float(prob[1]) * 100,
        "confidence_healthy": float(prob[0]) * 100,
        "frames_processed": len(all_kp)
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python inference.py <path_to_video>")
        sys.exit(1)
        
    video_file = sys.argv[1]
    res = predict_video(video_file)
    print("\n" + "="*40)
    print(" INFERENCE RESULTS ")
    print("="*40)
    print(f"  Prediction : {res['prediction']}")
    print(f"  Confidence : CP = {res['confidence_cp']:.1f}% | Healthy = {res['confidence_healthy']:.1f}%")
    print(f"  Frames     : {res['frames_processed']}")
    print("="*40)
