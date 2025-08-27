# This application generates a random string and echoes it with a UTC timestamp to standard output.
import random
import string
from time import sleep
from datetime import datetime, timezone


def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

if __name__ == "__main__":
    # Example output: "2020-03-30T12:15:22.705Z: - aB3dE5fGh1"
    while True:
        random_string = generate_random_string()

        now = datetime.now(timezone.utc)
        current_time = now.strftime("%Y-%m-%dT%H:%M:%S") + f".{now.microsecond // 1000:03d}Z"
        print(f"{current_time}: - {random_string}", flush=True)
        sleep(5)
