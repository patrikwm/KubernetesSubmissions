# This application generates a random string and echoes it with a UTC timestamp to standard output.
import logging
import os
from datetime import datetime, timezone

from flask import Flask

app = Flask(__name__)

LOG_FILE          = os.getenv("LOG_FILE", "ping-pong.log")
FLASK_PORT        = 3000
PING_PONG_COUNTER = 0


logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )

@app.route('/pingpong')
def get_status():
    """Endpoint to get the pingpong counter"""
    global PING_PONG_COUNTER
    result = f"pong {PING_PONG_COUNTER}"
    PING_PONG_COUNTER += 1

    try:
        with open(f"{LOG_FILE}", "w") as f:
            f.write(f"{PING_PONG_COUNTER}")
    except FileNotFoundError:
        return f"Could not find logfile {LOG_FILE}"
    return result


if __name__ == '__main__':
    # Generate initial random string
    logging.info(f"Server started in port {FLASK_PORT}")
    app.run(host='0.0.0.0', port=FLASK_PORT)
