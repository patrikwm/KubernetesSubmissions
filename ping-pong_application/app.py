# This application provides a ping-pong counter endpoint and logs to shared storage.
import logging
import os
import random
import string
from pathlib import Path
from datetime import datetime, timezone

from flask import Flask

app = Flask(__name__)

# --- Config ---
DATA_ROOT = Path(os.environ.get("DATA_ROOT", "./shared"))
LOGS_DIR = DATA_ROOT / "logs"
LOG_FILE = os.environ.get("LOG_FILE", "ping-pong.log")
FLASK_PORT = int(os.environ.get("PORT", "3000"))

# --- Paths ---
LOG_PATH = LOGS_DIR / LOG_FILE

# --- Global State ---
PING_PONG_COUNTER = 0

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("ping-pong-svc")

def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

@app.route('/pingpong')
def get_status():
    """Endpoint to get the pingpong counter"""
    global PING_PONG_COUNTER
    result = f"pong {PING_PONG_COUNTER}"
    PING_PONG_COUNTER += 1

    # Ensure logs directory exists
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    try:
        with open(LOG_PATH, "w") as f:
            f.write(str(PING_PONG_COUNTER))
        log.debug("Updated ping-pong counter to %d", PING_PONG_COUNTER)
    except Exception as e:
        log.error("Error writing to log file %s: %s", LOG_PATH, e)
        return f"Error writing to logfile {LOG_FILE}"

    return result

# Default port:
if __name__ == '__main__':
    APP_HASH = generate_random_string(6)

    log.info("Ping-pong server started on port %d", FLASK_PORT)
    log.info("App instance hash: %s", APP_HASH)
    app.run(host='0.0.0.0', port=FLASK_PORT)
