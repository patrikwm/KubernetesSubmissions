import logging
import os
import random
import string

from flask import Flask

app = Flask(__name__)
logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )

FLASK_PORT = int(os.environ.get("PORT", 8080))


def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

APP_HASH = generate_random_string(6)

@app.route('/')
def home():
    home_return_string = "<strong>App instance hash:</strong> {0}<br>".format(APP_HASH)
    home_return_string += "<strong>User request hash:</strong> {0}\n".format(generate_random_string(6))
    return home_return_string

# Default port:
if __name__ == '__main__':
    logging.info("Server started in port {0}".format(FLASK_PORT))
    logging.info("App instance hash: {0}".format(APP_HASH))
    app.run(host='0.0.0.0', port=FLASK_PORT)
