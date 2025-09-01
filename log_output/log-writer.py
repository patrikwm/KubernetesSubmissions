# This application generates a random string and echoes it with a UTC timestamp to standard output.
import os
import signal
import logging
import threading
import random
import string
from time import sleep
from pathlib import Path
from datetime import datetime, timezone

# --- Config ---
DATA_ROOT    = Path(os.environ.get("DATA_ROOT", "./shared"))
LOGS_DIR     = DATA_ROOT / "logs"
LOG_FILE     = os.environ.get("LOG_FILE", "log_output.log")
SLEEP_SEC    = int(os.environ.get("SLEEP_SEC", "5"))

# --- Paths ---
LOG_PATH = LOGS_DIR / LOG_FILE

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("log-writer-svc")

# --- Stop flag (works for SIGTERM, SIGINT, and KeyboardInterrupt) ---
stop = threading.Event()

def _signal_stop(*_):
    log.info("Shutdown signal received — finishing current cycle.")
    stop.set()

# Handle both k8s (SIGTERM) and local Ctrl+C (SIGINT)
signal.signal(signal.SIGTERM, _signal_stop)
signal.signal(signal.SIGINT,  _signal_stop)

# --- File logging setup ---
def setup_file_logging():
    """Set up file logging to shared directory."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    file_handler = logging.FileHandler(LOG_PATH, encoding='utf-8')
    file_handler.setLevel(logging.INFO)
    file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    file_handler.setFormatter(file_formatter)

    file_logger = logging.getLogger("file-logger")
    file_logger.setLevel(logging.INFO)
    file_logger.addHandler(file_handler)
    return file_logger

def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

def get_current_timestamp():
    """Get the current UTC timestamp in the required format."""
    now = datetime.now(timezone.utc)
    return now.strftime("%Y-%m-%dT%H:%M:%S") + f".{now.microsecond // 1000:03d}Z"

def main():
    """Main application loop."""
    # Set up file logging
    file_logger = setup_file_logging()

    # Generate initial random string
    initial_string = generate_random_string()
    initial_timestamp = get_current_timestamp()

    log.info("Log writer started with server ID: %s", initial_string)
    file_logger.info("Server started with hash %s", initial_string)

    current_status = {
        "timestamp": initial_timestamp,
        "random_string": initial_string
    }

    # Main loop
    while not stop.is_set():
        try:
            current_status["timestamp"] = get_current_timestamp()
            current_status["random_string"] = generate_random_string()

            # Output to stdout
            print(f"""{current_status["timestamp"]} - {current_status["random_string"]}""", flush=True)

            # Log to file
            file_logger.info('server id: %s - hash: %s', initial_string, current_status["random_string"])

            # Wait, but wake up early if a signal arrives
            stop.wait(SLEEP_SEC)

        except Exception as e:
            log.exception("Unexpected error: %s", e)
            stop.wait(min(5, SLEEP_SEC))

    log.info("Shutdown complete. Bye!")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        # In case Ctrl+C happens outside wait(), ensure graceful exit code
        _signal_stop()
        log.info("Interrupted by user. Exiting cleanly.")


