import logging
import os
import random
import signal
import string
import threading
from pathlib import Path

from flask import Flask

app = Flask(__name__)

# --- Config ---
DATA_DIR     = Path(os.environ.get("DATA_DIR", "../image-downloader/.data"))
CACHE_NAME   = os.environ.get("CACHE_NAME", "cache")
IMG_NAME     = os.environ.get("IMG_NAME", "image.jpg")
STAMP_NAME   = os.environ.get("STAMP_NAME", ".timestamp")
MARKER_NAME  = os.environ.get("MARKER_NAME", ".stale_once")
MAX_AGE_SEC  = int(os.environ.get("MAX_AGE_SEC", "600"))
HTTP_TIMEOUT = int(os.environ.get("HTTP_TIMEOUT", "20"))
FLASK_PORT   = int(os.environ.get("PORT", 8080))

# --- Paths ---
IMG_PATH   = DATA_DIR / IMG_NAME
CACHE_PATH = DATA_DIR / CACHE_NAME
STAMP_PATH = DATA_DIR / STAMP_NAME
MARK_PATH  = DATA_DIR / MARKER_NAME

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("todo-svc")


def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def get_image():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    # image = get cached image.
    # if no cache image. get image from shared directory and save in cache.
    # if cache image timestamp is older than 10 minutes.
    # Get new image from shared directory and save in the cache.
    # return image
    # If no image in shared dir. return no image found in shared dir.

@app.route('/todo')
def home():
    result = f"<strong>App instance hash:</strong> {APP_HASH}<br>"
    result += f"<strong>User request hash:</strong> {generate_random_string(6)}\n"
    result += f"SHOW-IMAGE "
    return result

# Default port:
if __name__ == '__main__':
    APP_HASH = generate_random_string(6)

    logging.info("Server started in port {0}".format(FLASK_PORT))
    logging.info("App instance hash: {0}".format(APP_HASH))
    app.run(host='0.0.0.0', port=FLASK_PORT)
