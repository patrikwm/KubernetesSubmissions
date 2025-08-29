# This application generates a random string and echoes it with a UTC timestamp to standard output.
import random
import logging
import string
import os
from time import sleep
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)
FLASK_PORT = 3000
LOG_FILE = os.environ.get("LOG_FILE", "log_output.log")


logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )




def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def get_current_timestamp():
    """Get the current UTC timestamp in the required format."""
    now = datetime.now(timezone.utc)
    return now.strftime("%Y-%m-%dT%H:%M:%S") + f".{now.microsecond // 1000:03d}Z"

current_status = {
    "timestamp": "",
    "random_string": ""
}

initial_string = generate_random_string()
initial_timestamp = get_current_timestamp()
current_status["timestamp"] = initial_timestamp
current_status["random_string"] = initial_string

logging.info("Server started in port {0}".format(FLASK_PORT))
logging.info("Initial random string: {0}".format(initial_string))


@app.route('/')
def get_status():
    """Endpoint to get the current status (timestamp and random string)."""
    try:
        with open(f"{LOG_FILE}", "r") as f:
            LOG_LINES = f.readlines()
    except Exception:
        return f"Could not find logfile {LOG_FILE}"
    result = f"<h1>HTTP Server ID: {initial_string}</h1><br>"
    for line in LOG_LINES:
        result += f"{line}<br>"
    return result

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=FLASK_PORT)
