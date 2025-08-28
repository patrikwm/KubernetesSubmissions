# This application generates a random string and echoes it with a UTC timestamp to standard output.
import logging
from time import sleep
from datetime import datetime, timezone

from flask import Flask

app = Flask(__name__)
FLASK_PORT = 3000

logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )

PING_PONG_COUNTER = 0

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
