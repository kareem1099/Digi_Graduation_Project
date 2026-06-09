"""
run.py — Start the FastAPI server locally.

Usage:
    # Default (localhost, port 8000)
    python run.py

    # Custom host/port
    python run.py --host 127.0.0.1 --port 8000

    # With hot-reload for development
    python run.py --reload

    # Custom checkpoint path
    set CHECKPOINT_PATH=models/best_w2v_ecapa.pt
    python run.py

    # Or on Linux/Mac:
    CHECKPOINT_PATH=models/best_w2v_ecapa.pt python run.py
"""

import argparse
import uvicorn

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host",    default="0.0.0.0")
    parser.add_argument("--port",    type=int, default=8000)
    parser.add_argument("--reload",  action="store_true",
                        help="Hot-reload on code changes (dev only)")
    parser.add_argument("--workers", type=int, default=1,
                        help="Number of worker processes. Keep 1 for GPU — "
                             "multiple workers each load the model separately.")
    args = parser.parse_args()

    uvicorn.run(
        "app.main:app",
        host    = args.host,
        port    = args.port,
        reload  = args.reload,
        workers = args.workers,
        log_level = "info",
    )
