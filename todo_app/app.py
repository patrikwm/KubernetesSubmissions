# app.py
from flask import Flask
from pathlib import Path
from datetime import datetime, timezone, timedelta
import base64, os, requests, logging

app = Flask(__name__)

# --- config (change only if you want) ---
DATA_ROOT = Path(os.environ.get("DATA_ROOT", "./shared"))
IMG_DIR = DATA_ROOT / "images"
IMG_PATH = IMG_DIR / "image.jpg"
TS_PATH  = IMG_DIR / ".ts"
MAX_AGE_SEC = int(os.environ.get("MAX_AGE_SEC", "600"))  # 10 minutes
PICSUM_URL = os.environ.get("PICSUM_URL", "https://picsum.photos/1200")

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("todo-app-svc")

def setup_file_logging():
    """Set up file logging to shared directory."""
    log_dir = Path("/app/logs")
    log_dir.mkdir(parents=True, exist_ok=True)
    app_log_path = log_dir / "todo-app.log"
    file_handler = logging.FileHandler(app_log_path, encoding='utf-8')
    file_handler.setLevel(logging.INFO)
    file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    file_handler.setFormatter(file_formatter)
    log.addHandler(file_handler)
    log.info("File logging enabled to %s", app_log_path)

def _now(): return datetime.now(timezone.utc)

def _age_seconds() -> float | None:
    if not TS_PATH.exists(): return None
    try:
        ts = datetime.fromisoformat(TS_PATH.read_text().strip())
        return (_now() - ts).total_seconds()
    except Exception:
        return None

def _ensure_image_exists():
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    if not IMG_PATH.exists():
        log.info("Image doesn't exist, downloading new image")
        _download_new_image()

def _download_new_image():
    try:
        log.info("Downloading new image from %s", PICSUM_URL)
        r = requests.get(PICSUM_URL, timeout=8)
        r.raise_for_status()
        IMG_PATH.write_bytes(r.content)
        TS_PATH.write_text(_now().isoformat())
        log.info("Successfully downloaded and saved new image")
    except Exception as e:
        log.error("Error downloading new image: %s", e)
        raise

@app.route("/")
def home():
    log.info("Home endpoint accessed")
    _ensure_image_exists()

    # read current image to show (always)
    img_b64 = base64.b64encode(IMG_PATH.read_bytes()).decode("ascii")

    # if stale -> refresh AFTER we've read bytes so user sees current image
    age = _age_seconds()
    if age is None or age >= MAX_AGE_SEC:
        log.info("Image is stale (age: %s seconds), refreshing", age)
        try:
            _download_new_image()
        except Exception as e:
            # ignore any failure; user still got the current image
            log.warning("Failed to refresh image, serving current one: %s", e)
            pass
    else:
        log.info("Image age: %s, timeout: %s", age, MAX_AGE_SEC)

    # super simple page
    return f"""
    <h1>The project App</h1>
    <img src="data:image/jpeg;base64,{img_b64}" width="400"><br>
    <small>DevOps with Kubernetes 2025</small>
    """

@app.route("/_shutdown")
def shutdown():
    # For testing persistence behavior
    os._exit(0)

if __name__ == "__main__":
    setup_file_logging()
    _ensure_image_exists()
    port = int(os.environ.get("PORT", "3000"))
    log.info("Todo app server started on port %d", port)
    app.run(host="0.0.0.0", port=port)