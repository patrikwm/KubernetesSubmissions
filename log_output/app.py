# This application generates a random string and echoes it with a UTC timestamp to standard output.
import random
import logging
import string
import threading
from time import sleep
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)
FLASK_PORT = 3000

logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )

current_status = {
    "timestamp": "",
    "random_string": ""
}

def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def get_current_timestamp():
    """Get the current UTC timestamp in the required format."""
    now = datetime.now(timezone.utc)
    return now.strftime("%Y-%m-%dT%H:%M:%S") + f".{now.microsecond // 1000:03d}Z"

def log_output_loop():
    """Background thread that continuously generates and logs random strings."""
    while True:
        random_string = generate_random_string()
        timestamp = get_current_timestamp()

        # Update global status
        current_status["timestamp"] = timestamp
        current_status["random_string"] = random_string

        # Log to stdout
        print(f"{timestamp}: - {random_string}", flush=True)
        sleep(5)

@app.route('/')
def get_status():
    """Endpoint to get the current status (timestamp and random string)."""
    return jsonify({
        "timestamp": current_status["timestamp"],
        "random_string": current_status["random_string"]
    })

if __name__ == '__main__':
    # Generate initial random string
    initial_string = generate_random_string()
    initial_timestamp = get_current_timestamp()
    current_status["timestamp"] = initial_timestamp
    current_status["random_string"] = initial_string

    # Start the background logging thread
    log_thread = threading.Thread(target=log_output_loop, daemon=True)
    log_thread.start()

    logging.info("Server started in port {0}".format(FLASK_PORT))
    logging.info("Initial random string: {0}".format(initial_string))
    app.run(host='0.0.0.0', port=FLASK_PORT)
