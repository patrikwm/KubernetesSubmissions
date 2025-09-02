# This application reads logs from shared storage and displays them via HTTP endpoint.
import os
import logging
import string
import uuid
import requests
from pathlib import Path
from datetime import datetime, timezone

from flask import Flask

app = Flask(__name__)

# --- Config ---
DATA_ROOT = Path(os.environ.get("DATA_ROOT", "./shared"))
LOGS_DIR = DATA_ROOT / "logs"

LOG_FILE = os.environ.get("LOG_FILE", "log_output.log")
PING_PONG_URL = os.getenv(
    "PING_PONG_URL",
    "http://ping-pong-svc:2345/pings"
)
APP_LOG_FILE = os.environ.get("APP_LOG_FILE", "log-reader.log")
FLASK_PORT = int(os.environ.get("PORT", "3000"))

# --- Paths ---
LOG_PATH = LOGS_DIR / LOG_FILE
APP_LOG_PATH = LOGS_DIR / APP_LOG_FILE

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("log-reader-svc")

def setup_file_logging():
    """Set up file logging to shared directory."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    file_handler = logging.FileHandler(APP_LOG_PATH, encoding='utf-8')
    file_handler.setLevel(logging.INFO)
    file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    file_handler.setFormatter(file_formatter)
    log.addHandler(file_handler)
    log.info("File logging enabled to %s", APP_LOG_PATH)

def generate_random_string():
    """Generate a random string of fixed length."""
    return uuid.uuid4()

def get_current_timestamp():
    """Get the current UTC timestamp in the required format."""
    now = datetime.now(timezone.utc)
    return now.strftime("%Y-%m-%dT%H:%M:%S") + f".{now.microsecond // 1000:03d}Z"

def fetch_ping_pong():
    """Fetch JSON from the ping-pong service and return the counter."""
    try:
        resp = requests.get(PING_PONG_URL, timeout=2)
        resp.raise_for_status()
        data = resp.json()
        return int(data.get("counter", 0))
    except Exception as e:
        log.error("Error calling ping-pong service: %s", e)
        return None

@app.route('/')
def get_status():
    """Endpoint to get the current status (timestamp and random string)."""
    result = f"HTTP Server ID: {APP_HASH}\n<br>"

    # Call ping-pong service
    counter = fetch_ping_pong()
    if counter is not None:
        result += f"Ping / Pongs: {counter}\n</br></br>"
    else:
        result += "Ping / Pongs: unavailable\n</br></br>"

    # Read main log
    try:
        if LOG_PATH.exists():
            with open(LOG_PATH, "r") as f:
                log_lines = f.readlines()
            for line in log_lines[-10:]:
                result += f"{line}<br>"
        else:
            result += f"Could not find logfile {LOG_FILE}"
    except Exception as e:
        log.error("Error reading main log: %s", e)
        result += f"Error reading {LOG_FILE}"

    return result

# Default port:
if __name__ == '__main__':
    setup_file_logging()
    APP_HASH = generate_random_string()

    log.info("Log reader server started on port %d", FLASK_PORT)
    log.info("App instance hash: %s", APP_HASH)
    app.run(host='0.0.0.0', port=FLASK_PORT)
