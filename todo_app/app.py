# This application displays todo items with cached images from shared storage.
import base64
import logging
import os
import random
import shutil
import string
from pathlib import Path
from datetime import datetime, timezone

from flask import Flask

app = Flask(__name__)

# --- Config ---
DATA_ROOT = Path(os.environ.get("DATA_ROOT", "./shared"))
IMAGES_DIR = DATA_ROOT / "images"
CACHE_DIR = IMAGES_DIR / "cache"
IMG_NAME = os.environ.get("IMG_NAME", "image.jpg")
STAMP_NAME = os.environ.get("STAMP_NAME", ".timestamp")
MAX_AGE_SEC = int(os.environ.get("MAX_AGE_SEC", "600"))
FLASK_PORT = int(os.environ.get("PORT", "8080"))

# --- Paths ---
SHARED_IMG_PATH = IMAGES_DIR / IMG_NAME
CACHED_IMG_PATH = CACHE_DIR / IMG_NAME
STAMP_PATH = IMAGES_DIR / STAMP_NAME

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("todo-svc")


def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def get_image():
    """Get image from shared storage with caching logic"""
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    # Check if we have a cached image and if it's still valid
    if CACHED_IMG_PATH.exists() and STAMP_PATH.exists():
        try:
            timestamp = datetime.fromisoformat(STAMP_PATH.read_text().strip())
            age = datetime.now(timezone.utc) - timestamp
            if age.total_seconds() < MAX_AGE_SEC:  # Still valid
                log.debug("Using cached image (age: %.1f seconds)", age.total_seconds())
                return CACHED_IMG_PATH
        except (ValueError, FileNotFoundError) as e:
            log.warning("Invalid timestamp file: %s", e)

    # Cache is stale or missing, try to get from shared storage
    if SHARED_IMG_PATH.exists():
        # Copy shared image to cache
        try:
            shutil.copy2(SHARED_IMG_PATH, CACHED_IMG_PATH)
            log.info("Updated cache from shared storage")
            return CACHED_IMG_PATH
        except Exception as e:
            log.error("Failed to copy image to cache: %s", e)

    # No image available
    log.warning("No image found in shared storage at %s", SHARED_IMG_PATH)
    return None

@app.route('/todo')
def home():
    """Main todo application endpoint with image display"""
    result = f"<strong>App instance hash:</strong> {APP_HASH}<br>"
    result += f"<strong>User request hash:</strong> {generate_random_string(6)}<br>"

    image_path = get_image()
    if image_path and image_path.exists():
        try:
            # Convert image to base64 for inline display
            with open(image_path, 'rb') as f:
                img_data = base64.b64encode(f.read()).decode()
            result += f'<br><img src="data:image/jpeg;base64,{img_data}" width="400"><br>'
            result += f"<em>Image from: {image_path}</em><br>"
        except Exception as e:
            log.error("Error displaying image: %s", e)
            result += f"<br>Error loading image: {e}<br>"
    else:
        result += "<br>No image available<br>"

    return result

# Default port:
if __name__ == '__main__':
    APP_HASH = generate_random_string(6)

    log.info("Todo server started on port %d", FLASK_PORT)
    log.info("App instance hash: %s", APP_HASH)
    app.run(host='0.0.0.0', port=FLASK_PORT)
