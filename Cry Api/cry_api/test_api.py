"""
test_api.py
-----------
Simple script to test the FastAPI endpoints locally.
Place test audio files in data/test/ and run this script.

Usage:
    python test_api.py
"""

import os
import json
import time
import requests
from pathlib import Path

# Configuration
BASE_URL = "http://127.0.0.1:8000"
TEST_DATA_DIR = Path("data/test")
SUPPORTED_EXTS = {".wav", ".mp3", ".ogg", ".m4a", ".flac", ".opus", ".aac"}


def test_health():
    """Test the health endpoint."""
    print("\n[1] Testing /health endpoint...")
    try:
        r = requests.get(f"{BASE_URL}/health", timeout=5)
        r.raise_for_status()
        data = r.json()
        print(f"  ✓ Status: {data['status']}")
        print(f"  ✓ Device: {data['device']}")
        print(f"  ✓ Classes: {data['classes']}")
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def test_classes():
    """Test the classes endpoint."""
    print("\n[2] Testing /classes endpoint...")
    try:
        r = requests.get(f"{BASE_URL}/classes", timeout=5)
        r.raise_for_status()
        data = r.json()
        print(f"  ✓ Classes ({data['n_classes']}): {data['classes']}")
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def test_predict_file(audio_path: str):
    """Test the predict endpoint with file upload."""
    print(f"\n[3] Testing /predict with file upload: {Path(audio_path).name}...")
    try:
        with open(audio_path, "rb") as f:
            files = {"file": (Path(audio_path).name, f, "audio/wav")}
            r = requests.post(f"{BASE_URL}/predict", files=files, timeout=120)
        r.raise_for_status()
        data = r.json()
        
        print(f"  ✓ Filename: {data['filename']}")
        print(f"  ✓ Duration: {data['duration_sec']:.2f}s")
        print(f"  ✓ Segments found: {data['n_segments']}")
        print(f"  ✓ Processing time: {data.get('processing_ms', '?')}ms")
        
        if data['segments']:
            for i, seg in enumerate(data['segments'], 1):
                print(f"\n    Segment {i}:")
                print(f"      Time: {seg['start_sec']:.2f}s - {seg['end_sec']:.2f}s")
                print(f"      Label: {seg['label']}")
                print(f"      Confidence: {seg['confidence']:.4f}")
                print(f"      Windows: {seg['n_windows']}")
                print(f"      Probs: {seg['all_probs']}")
        else:
            print("  (no speech segments detected)")
        
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def test_predict_server_path(audio_path: str):
    """Test the predict/file endpoint (server-side path)."""
    print(f"\n[4] Testing /predict/file with server path: {Path(audio_path).name}...")
    try:
        r = requests.get(
            f"{BASE_URL}/predict/file",
            params={"path": os.path.abspath(audio_path)},
            timeout=120
        )
        r.raise_for_status()
        data = r.json()
        print(f"  ✓ Successfully classified via server path")
        print(f"  ✓ Found {data['n_segments']} segment(s)")
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def main():
    print("=" * 70)
    print("FastAPI Cry Classifier - Local Test Suite")
    print("=" * 70)
    print(f"Base URL: {BASE_URL}")
    print(f"Test data dir: {TEST_DATA_DIR.absolute()}")
    
    # Check if server is reachable
    print("\nChecking if server is running...")
    try:
        requests.get(f"{BASE_URL}/health", timeout=2)
        print("✓ Server is running!")
    except Exception as e:
        print(f"✗ Server is not running. Start it with: python run.py")
        print(f"  Error: {e}")
        return
    
    # Run basic endpoint tests
    test_health()
    test_classes()
    
    # Test with audio files if they exist
    test_files = sorted([
        f for f in TEST_DATA_DIR.glob("*")
        if f.suffix.lower() in SUPPORTED_EXTS
    ])
    
    if test_files:
        print(f"\nFound {len(test_files)} test file(s) in data/test/")
        for audio_path in test_files[:2]:  # Test first 2 files
            test_predict_file(str(audio_path))
            # time.sleep(1)  # Avoid hammering the API
    else:
        print(f"\nℹ No test audio files found in {TEST_DATA_DIR}")
        print("  Place audio files (wav, mp3, etc.) in data/test/ to test inference")
    
    print("\n" + "=" * 70)
    print("Test complete!")
    print("=" * 70)


if __name__ == "__main__":
    main()
