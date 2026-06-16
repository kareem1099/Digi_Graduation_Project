"""
feature_fusion.py
------------------
Assembles the 14 loaded feature matrices into the three fusion strategies
used in the paper:

  - PoseFusion      : orientation-based features concatenated
  - VelocityFusion  : displacement-based features concatenated
  - PoseVelFusion   : all features combined (best performing)

Also defines the individual feature sets (TNSRE_Ind).

Equivalent to the "INDIVIDUAL JOINT HISTOGRAMS and Feature Fusion" and
"TNSRE Feature sets" sections of B_Classification_RVI.m
"""

import numpy as np


def build_feature_sets(feats: dict) -> dict:
    """
    Build all feature matrices from the loaded per-joint arrays.

    Parameters
    ----------
    feats : dict
        Keys follow the convention  '<JointName><NumBins>'
        e.g. 'LeftWrist8', 'RightElbow16', 'Larm8', etc.

    Returns
    -------
    dict with keys:
        'TNSRE_Ind'         : list of 14 (n_vids, ?) matrices
        'TNSRE_Ind_Lbl'     : list of 14 label strings
        'PoseFusion'        : (n_vids, D_pose) matrix
        'PoseFusion_Lbl'    : 'PoseFused'
        'VelFusion'         : (n_vids, D_vel) matrix
        'VelFusion_Lbl'     : 'VelocityFused'
        'PoseVelFusion'     : (n_vids, D_all) matrix  ← used for classification
        'PoseVelFusion_Lbl' : 'PoseVelocity'
    """
    # ── Individual feature matrices ──────────────────────────────────────────
    # MATLAB names → what we store in feats
    #
    # A (HOJO2D):  LeftWrist/LeftElbow fused + LeftKnee/LeftAnkle fused, etc.
    A8  = np.hstack([feats["LeftWrist8"]  + feats["LeftElbow8"],
                     feats["LeftKnee8"]   + feats["LeftAnkle8"],
                     feats["RightWrist8"] + feats["RightElbow8"],
                     feats["RightKnee8"]  + feats["RightAnkle8"]])

    A16 = np.hstack([feats["LeftWrist16"]  + feats["LeftElbow16"],
                     feats["LeftKnee16"]   + feats["LeftAnkle16"],
                     feats["RightWrist16"] + feats["RightElbow16"],
                     feats["RightKnee16"]  + feats["RightAnkle16"]])

    # B (HOJD2D): concatenated per joint
    B8  = np.hstack([feats["LeftWrist8_d"],  feats["LeftElbow8_d"],
                     feats["LeftKnee8_d"],   feats["LeftAnkle8_d"],
                     feats["RightWrist8_d"], feats["RightElbow8_d"],
                     feats["RightKnee8_d"],  feats["RightAnkle8_d"]])

    B16 = np.hstack([feats["LeftWrist16_d"],  feats["LeftElbow16_d"],
                     feats["LeftKnee16_d"],   feats["LeftAnkle16_d"],
                     feats["RightWrist16_d"], feats["RightElbow16_d"],
                     feats["RightKnee16_d"],  feats["RightAnkle16_d"]])

    # C (FFTJO):  per joint
    C8  = np.hstack([feats["LeftWrist8_fjo"],  feats["LeftElbow8_fjo"],
                     feats["LeftKnee8_fjo"],   feats["LeftAnkle8_fjo"],
                     feats["RightWrist8_fjo"], feats["RightElbow8_fjo"],
                     feats["RightKnee8_fjo"],  feats["RightAnkle8_fjo"]])

    C16 = np.hstack([feats["LeftWrist16_fjo"],  feats["LeftElbow16_fjo"],
                     feats["LeftKnee16_fjo"],   feats["LeftAnkle16_fjo"],
                     feats["RightWrist16_fjo"], feats["RightElbow16_fjo"],
                     feats["RightKnee16_fjo"],  feats["RightAnkle16_fjo"]])

    # D (FFTJD): per joint
    D8  = np.hstack([feats["LeftWrist8_fjd"],  feats["LeftElbow8_fjd"],
                     feats["LeftKnee8_fjd"],   feats["LeftAnkle8_fjd"],
                     feats["RightWrist8_fjd"], feats["RightElbow8_fjd"],
                     feats["RightKnee8_fjd"],  feats["RightAnkle8_fjd"]])

    D16 = np.hstack([feats["LeftWrist16_fjd"],  feats["LeftElbow16_fjd"],
                     feats["LeftKnee16_fjd"],   feats["LeftAnkle16_fjd"],
                     feats["RightWrist16_fjd"], feats["RightElbow16_fjd"],
                     feats["RightKnee16_fjd"],  feats["RightAnkle16_fjd"]])

    # G (AngDisp): per joint
    G8  = np.hstack([feats["LeftWrist8_ang"],  feats["LeftElbow8_ang"],
                     feats["LeftKnee8_ang"],   feats["LeftAnkle8_ang"],
                     feats["RightWrist8_ang"], feats["RightElbow8_ang"],
                     feats["RightKnee8_ang"],  feats["RightAnkle8_ang"]])

    G16 = np.hstack([feats["LeftWrist16_ang"],  feats["LeftElbow16_ang"],
                     feats["LeftKnee16_ang"],   feats["LeftAnkle16_ang"],
                     feats["RightWrist16_ang"], feats["RightElbow16_ang"],
                     feats["RightKnee16_ang"],  feats["RightAnkle16_ang"]])

    # H (Rel_JO limb groups)
    H8  = np.hstack([feats["Larm8_rjo"],  feats["Lleg8_rjo"],
                     feats["Rarm8_rjo"],  feats["Rleg8_rjo"]])
    H16 = np.hstack([feats["Larm16_rjo"], feats["Lleg16_rjo"],
                     feats["Rarm16_rjo"], feats["Rleg16_rjo"]])

    # I (Rel_JO_AngDis limb groups)
    I8  = np.hstack([feats["Larm8_rjad"],  feats["Lleg8_rjad"],
                     feats["Rarm8_rjad"],  feats["Rleg8_rjad"]])
    I16 = np.hstack([feats["Larm16_rjad"], feats["Lleg16_rjad"],
                     feats["Rarm16_rjad"], feats["Rleg16_rjad"]])

    # ── Fusion strategies (matching MATLAB exactly) ───────────────────────────
    # PoseFusion   : [G16 A8 H8 C16]
    pose_fusion = np.hstack([G16, A8, H8, C16])

    # VelocityFusion : [B16 D8 I8]
    vel_fusion  = np.hstack([B16, D8, I8])

    # PoseVelocityFusion : [G16 B16 D16 A8 H8 C16 I8]
    pose_vel_fusion = np.hstack([G16, B16, D16, A8, H8, C16, I8])

    return {
        # Individual
        "TNSRE_Ind":     [A8, A16, B8, B16, C8, C16, D8, D16,
                          G8, G16, H8, H16, I8, I16],
        "TNSRE_Ind_Lbl": ["HOJO2D_8",  "HOJO2D_16",
                          "HOJD2D_8",  "HOJD2D_16",
                          "FFTJO_8",   "FFTJO_16",
                          "FFTJD_8",   "FFTJD_16",
                          "AngDisp_8", "AngDisp_16",
                          "Rel_JO_8",  "Rel_JO_16",
                          "Rel_JO_AngD_8", "Rel_JO_AngD_16"],
        # Fused
        "PoseFusion":        pose_fusion,
        "PoseFusion_Lbl":    "PoseFused",
        "VelFusion":         vel_fusion,
        "VelFusion_Lbl":     "VelocityFused",
        "PoseVelFusion":     pose_vel_fusion,
        "PoseVelFusion_Lbl": "PoseVelocity",
    }
