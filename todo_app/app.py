from flask import Flask
import logging
import os

app = Flask(__name__)
logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )

FLASK_PORT = int(os.environ.get("PORT", 8080))

@app.route('/')
def home():
    return "Welcome to the To-Do List API!"

# Default port:
if __name__ == '__main__':
    logging.info("Server started in port {0}".format(FLASK_PORT))
    app.run(host='0.0.0.0', port=FLASK_PORT)