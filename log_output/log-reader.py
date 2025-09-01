# This application reads logs from shared storage and displays them via HTTP endpoint.
import os
import logging
import string
import random
from pathlib import Path
from datetime import datetime, timezone

from flask import Flask

app = Flask(__name__)

# --- Config ---
DATA_ROOT = Path(os.environ.get("DATA_ROOT", "./shared"))
LOGS_DIR = DATA_ROOT / "logs"
LOG_FILE = os.environ.get("LOG_FILE", "log_output.log")
PING_PONG_LOG_FILE = os.environ.get("PING_PONG_LOG_FILE", "ping-pong.log")
FLASK_PORT = int(os.environ.get("PORT", "3000"))

# --- Paths ---
LOG_PATH = LOGS_DIR / LOG_FILE
PING_PONG_PATH = LOGS_DIR / PING_PONG_LOG_FILE

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("log-reader-svc")

def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def get_current_timestamp():
    """Get the current UTC timestamp in the required format."""
    now = datetime.now(timezone.utc)
    return now.strftime("%Y-%m-%dT%H:%M:%S") + f".{now.microsecond // 1000:03d}Z"

@app.route('/')
def get_status():
    """Endpoint to get the current status (timestamp and random string)."""
    result = f"<h1>HTTP Server ID: {APP_HASH}</h1><br>"

    # Read ping-pong log
    try:
        if PING_PONG_PATH.exists():
            with open(PING_PONG_PATH, "r") as ping_pong_f:
                ping_pong_lines = ping_pong_f.readline()
        else:
            ping_pong_lines = "No ping-pong log found"
    except Exception as e:
        log.error("Error reading ping-pong log: %s", e)
        ping_pong_lines = f"Error reading {PING_PONG_LOG_FILE}"

    result += f"Ping / Pongs: {ping_pong_lines}</br></br>"

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
    APP_HASH = generate_random_string(6)

    log.info("Log reader server started on port %d", FLASK_PORT)
    log.info("App instance hash: %s", APP_HASH)
    app.run(host='0.0.0.0', port=FLASK_PORT)
