"""
utils.py
--------
Shared helper functions for all feature extraction modules.
"""

import numpy as np
from scipy.spatial.distance import cdist


def get_rotation_mat(angle_rad: float) -> np.ndarray:
    """Return a 2×2 rotation matrix for angle (radians)."""
    c, s = np.cos(angle_rad), np.sin(angle_rad)
    return np.array([[c, -s], [s, c]])


def build_bin_vectors(num_bin: int) -> np.ndarray:
    """
    Build an array of unit direction vectors spread evenly around the circle.
    Used as histogram bin centres for orientation features.

    Returns
    -------
    bin_vecs : np.ndarray (2, num_bin)
        Each column is a 2D unit vector for that bin.
    """
    theta = (2 * np.pi) / num_bin
    base  = np.array([0.0, 1.0])
    bin_vecs = np.zeros((2, num_bin))
    for i in range(1, num_bin + 1):
        rM = get_rotation_mat(i * theta)
        bin_vecs[:, i - 1] = rM @ base
    return bin_vecs


def build_ang_dis_bins(num_bin: int, max_degree: float = 180.0) -> np.ndarray:
    """
    Build logarithmically-spaced angular-displacement bin boundaries.

    Matches MATLAB:
        AngDisBins(numBin) = 180;
        for i = numBin-1:-1:1
            AngDisBins(i) = maxDegree/2;  maxDegree = AngDisBins(i)
        end
    Result (8-bin): [1.406, 2.813, 5.625, 11.25, 22.5, 45, 90, 180]
    """
    bins = np.zeros(num_bin)
    bins[num_bin - 1] = max_degree
    cur = max_degree
    for i in range(num_bin - 2, -1, -1):
        cur      = cur / 2.0
        bins[i]  = cur
    return bins


def get_hist_cosine(vec: np.ndarray, bin_vecs: np.ndarray) -> np.ndarray:
    """
    Assign vec to the single closest bin using cosine distance.
    Used in Rel_JO (getHist with continuous=True).

    Parameters
    ----------
    vec      : (2,) unit vector
    bin_vecs : (2, num_bin)

    Returns
    -------
    hist : (num_bin,) one-hot array
    """
    num_bin  = bin_vecs.shape[1]
    hist     = np.zeros(num_bin)
    dists    = cdist(vec.reshape(1, 2), bin_vecs.T, metric="cosine")[0]
    hist[np.argmin(dists)] = 1.0
    return hist


def get_hist_hojo(vec: np.ndarray, bin_vecs: np.ndarray,
                  share_weight: bool = True) -> np.ndarray:
    """
    Assign vec to histogram bins using cosine distance.
    When share_weight=True, weight is spread between the 2 nearest bins
    (inverse-distance weighting). Used in HOJO2D.

    Parameters
    ----------
    vec          : (2,) unit vector (already normalised)
    bin_vecs     : (2, num_bin)
    share_weight : bool — if True use 2-bin soft assignment

    Returns
    -------
    hist : (num_bin,) array
    """
    num_bin = bin_vecs.shape[1]
    hist    = np.zeros(num_bin)
    dists   = cdist(vec.reshape(1, 2), bin_vecs.T, metric="cosine")[0]

    if not share_weight:
        hist[np.argmin(dists)] = 1.0
    else:
        # Take 2 nearest bins
        sorted_idx = np.argsort(dists)
        i0, i1     = sorted_idx[0], sorted_idx[1]
        d0, d1     = dists[i0], dists[i1]
        total      = d0 + d1
        if total > 0:
            # Inverse weighting: closer bin gets weight proportional to other's distance
            hist[i0] = d1 / total
            hist[i1] = d0 / total
        else:
            hist[i0] = 1.0
    return hist


def get_hist_discrete(val: float, bins: np.ndarray) -> np.ndarray:
    """
    Assign a scalar value to a bin via simple threshold comparison.
    Used for AngDis features (getHist with continuous=False).

    Returns
    -------
    hist : (num_bin,) one-hot array
    """
    hist = np.zeros(len(bins))
    for cc, b in enumerate(bins):
        if val < b:
            hist[cc] = 1.0
            return hist
    # If val >= all thresholds, assign to last bin
    hist[-1] = 1.0
    return hist


def fft_power_spectrum(signal: np.ndarray, fs: float = 50.0):
    """
    Compute the single-sided FFT power spectrum.

    Returns
    -------
    P1 : np.ndarray  — amplitude spectrum (single-sided)
    f  : np.ndarray  — frequency axis in Hz
    """
    L  = len(signal)
    Y  = np.fft.fft(signal)
    P2 = np.abs(Y / L)
    P1 = P2[:L // 2 + 1]
    P1[1:-1] *= 2
    f  = fs * np.arange(L // 2 + 1) / L
    return P1, f


def assign_fft_bin_absolute(f_val: float, max_f: float,
                             num_bin: int, pwr: float) -> int:
    """
    Assign a frequency to a bin using ABSOLUTE power-law boundaries.
    Used for FFT_JD 8-bin (pwr=2): boundary_k = maxF * (k^pwr / numBin^pwr)

    Returns 0-based bin index.
    """
    for k in range(1, num_bin):
        if f_val < max_f * (k ** pwr / num_bin ** pwr):
            return k - 1          # 0-based
    return num_bin - 1


def assign_fft_bin_cumulative(f_val: float, max_f: float,
                               num_bin: int, pwr: float) -> int:
    """
    Assign a frequency to a bin using CUMULATIVE power-law boundaries.
    Used for FFT_JO 8-bin (pwr=20) and FFT_JD 16-bin (pwr=1.5).

    Matches MATLAB's accBins-accumulating logic.

    Returns 0-based bin index.
    """
    acc_bins = 0.0
    for k in range(1, num_bin):
        threshold = max_f * (acc_bins + (k ** pwr / num_bin ** pwr))
        if f_val < threshold:
            return k - 1          # 0-based
        acc_bins += k ** pwr / num_bin ** pwr
    return num_bin - 1
