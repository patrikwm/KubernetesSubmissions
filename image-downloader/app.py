import os
import signal
import logging
import threading
from pathlib import Path
from datetime import datetime, timezone, timedelta

import requests

# --- Config ---
DATA_ROOT   = Path(os.environ.get("DATA_ROOT", "./shared"))  # <-- one root
IMAGES_DIR  = DATA_ROOT / "images"
LOGS_DIR    = DATA_ROOT / "logs"

IMG_URL      = os.environ.get("IMG_URL", "https://picsum.photos/1200")
IMG_NAME     = os.environ.get("IMG_NAME", "image.jpg")
STAMP_NAME   = os.environ.get("STAMP_NAME", ".timestamp")
MARKER_NAME  = os.environ.get("MARKER_NAME", ".stale_once")
MAX_AGE_SEC  = int(os.environ.get("MAX_AGE_SEC", "600"))
HTTP_TIMEOUT = int(os.environ.get("HTTP_TIMEOUT", "20"))

# --- Paths ---
IMG_PATH   = IMAGES_DIR / IMG_NAME
STAMP_PATH = IMAGES_DIR / STAMP_NAME
MARK_PATH  = IMAGES_DIR / MARKER_NAME

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("image-svc")

# --- Stop flag (works for SIGTERM, SIGINT, and KeyboardInterrupt) ---
stop = threading.Event()

def _signal_stop(*_):
    log.info("Shutdown signal received — finishing current cycle.")
    stop.set()

# Handle both k8s (SIGTERM) and local Ctrl+C (SIGINT)
signal.signal(signal.SIGTERM, _signal_stop)
signal.signal(signal.SIGINT,  _signal_stop)

def touch_timestamp() -> None:
    DATA_ROOT.mkdir(parents=True, exist_ok=True)
    STAMP_PATH.write_text(datetime.now(timezone.utc).isoformat())

def download_new_image() -> int:
    log.info("Downloading a new image from %s ...", IMG_URL)
    r = requests.get(IMG_URL, timeout=HTTP_TIMEOUT)
    r.raise_for_status()
    DATA_ROOT.mkdir(parents=True, exist_ok=True)
    with open(IMG_PATH, "wb") as f:
        f.write(r.content)
    touch_timestamp()
    MARK_PATH.unlink(missing_ok=True)
    log.info("New image saved (%d bytes).", len(r.content))
    return len(r.content)

def get_timestamp() -> str | None:
    try:
        return STAMP_PATH.read_text().strip()
    except FileNotFoundError:
        return None

def is_stale(max_age_seconds: int) -> bool:
    ts = get_timestamp()
    if not ts:
        log.debug("No timestamp file found -> stale")
        return True
    try:
        ts_dt = datetime.fromisoformat(ts)
        now = datetime.now(timezone.utc)
        return now - ts_dt > timedelta(seconds=max_age_seconds)
    except ValueError as e:
        logging.error(f"Invalid timestamp format: {e!s} (contents: {ts!r})")
        return True

def main():
    log.info("Image downloader started.")
    while not stop.is_set():
        try:
            if is_stale(MAX_AGE_SEC):
                download_new_image()
            else:
                log.info("Cached image is still fresh.")
            log.info("Current timestamp: %r", get_timestamp())

            # Wait, but wake up early if a signal arrives
            stop.wait(MAX_AGE_SEC)
        except requests.RequestException as e:
            log.exception("Download failed: %s", e)
            # brief wait so we don't spin; still interruptible
            stop.wait(min(30, MAX_AGE_SEC))
        except Exception as e:
            log.exception("Unexpected error: %s", e)
            stop.wait(min(30, MAX_AGE_SEC))

    log.info("Shutdown complete. Bye!")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        # In case Ctrl+C happens outside wait(), ensure graceful exit code
        _signal_stop()
        log.info("Interrupted by user. Exiting cleanly.")