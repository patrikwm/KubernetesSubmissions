# This application generates a random string and echoes it with a UTC timestamp to standard output.
import random
import logging
import string
import os
from time import sleep
from datetime import datetime, timezone


LOG_FILE = os.environ.get("LOG_FILE", "log_output.log")

logger = logging.getLogger(__name__)

logging.basicConfig(filename=f"{LOG_FILE}", encoding='utf-8',
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


if __name__ == '__main__':
    # Generate initial random string
    initial_string = generate_random_string()
    initial_timestamp = get_current_timestamp()
    current_status["timestamp"] = initial_timestamp
    current_status["random_string"] = initial_string
    logging.info(f"Server started with hash {initial_string}")

    # Start the background logging thread
    while True:
        current_status["timestamp"] = get_current_timestamp()
        current_status["random_string"] = generate_random_string()
        print(f"""{current_status["timestamp"]} - {current_status["random_string"]}""", flush=True)
        logging.info(f'server id: {initial_string} - hash: {current_status["random_string"]}')
        sleep(5)


