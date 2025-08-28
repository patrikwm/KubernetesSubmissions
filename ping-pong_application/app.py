# This application generates a random string and echoes it with a UTC timestamp to standard output.
import logging
import string
from time import sleep
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)
FLASK_PORT = 3000

logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )

PING_PONG_COUNTER = 0

def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def get_current_timestamp():
    """Get the current UTC timestamp in the required format."""
    now = datetime.now(timezone.utc)
    return now.strftime("%Y-%m-%dT%H:%M:%S") + f".{now.microsecond // 1000:03d}Z"


@app.route('/pingpong')
def get_status():
    """Endpoint to get the pingpong counter"""
    global PING_PONG_COUNTER
    RESPONSE = f"pong {PING_PONG_COUNTER}"
    PING_PONG_COUNTER += 1
    return RESPONSE

if __name__ == '__main__':
    # Generate initial random string
    logging.info(f"Server started in port {FLASK_PORT}")
    app.run(host='0.0.0.0', port=FLASK_PORT)
