# FastAPI version of the ping-pong application with PostgreSQL
import logging
import os
import random
import string
from pathlib import Path
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import databases
import asyncpg

# --- Config ---
DATA_ROOT = Path(os.environ.get("DATA_ROOT", "./shared"))
LOGS_DIR = DATA_ROOT / "logs"

LOG_FILE = os.environ.get("LOG_FILE", "ping-pong.log")
APP_LOG_FILE = os.environ.get("APP_LOG_FILE", "ping-pong-app.log")
FLASK_PORT = int(os.environ.get("PORT", "3000"))

# PostgreSQL configuration
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", "127.0.0.1")
POSTGRES_PORT = int(os.environ.get("POSTGRES_PORT", "5432"))
POSTGRES_DB = os.environ.get("POSTGRES_DB", "postgres")
POSTGRES_USER = os.environ.get("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "example")

DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"

# --- Paths ---
LOG_PATH = LOGS_DIR / LOG_FILE
APP_LOG_PATH = LOGS_DIR / APP_LOG_FILE

# --- Database ---
database = databases.Database(DATABASE_URL)

# --- Global State ---
PING_PONG_COUNTER = 0
USE_DATABASE = True  # Flag to determine if database is available

# --- Logging ---
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("ping-pong-svc")

def setup_file_logging():
    """Set up file logging to shared directory."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    file_handler = logging.FileHandler(APP_LOG_PATH, encoding='utf-8')
    file_handler.setLevel(logging.INFO)
    file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    file_handler.setFormatter(file_formatter)
    log.addHandler(file_handler)
    log.info("File logging enabled to %s", APP_LOG_PATH)

def generate_random_string(length=10):
    """Generate a random string of fixed length."""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for i in range(length))

async def init_database():
    """Initialize the database connection and create tables if needed."""
    try:
        log.info(f"Attempting to connect to database: {DATABASE_URL.replace(POSTGRES_PASSWORD, '***')}")
        await database.connect()
        log.info("Connected to PostgreSQL database")

        # Test basic connectivity
        test_result = await database.fetch_val("SELECT 1")
        log.info(f"Database connectivity test successful: {test_result}")

        # Create the ping_pong table if it doesn't exist
        query = """
        CREATE TABLE IF NOT EXISTS ping_pong (
            id SERIAL PRIMARY KEY,
            counter INTEGER NOT NULL DEFAULT 0,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        await database.execute(query)
        log.info("Ping-pong table created or already exists")

        # Initialize counter if table is empty
        count_query = "SELECT COUNT(*) FROM ping_pong"
        count = await database.fetch_val(count_query)
        log.info(f"Current records in ping_pong table: {count}")

        if count == 0:
            init_query = "INSERT INTO ping_pong (counter) VALUES (0)"
            await database.execute(init_query)
            log.info("Initialized ping-pong counter in database with value 0")
        else:
            # Get current counter value
            current_value = await get_counter_from_db()
            log.info(f"Ping-pong counter already exists in database with value: {current_value}")

    except Exception as e:
        log.error("Error initializing database: %s", e)
        log.error(f"Database URL (sanitized): {DATABASE_URL.replace(POSTGRES_PASSWORD, '***')}")
        raise

async def get_counter_from_db():
    """Get the current counter value from database."""
    try:
        query = "SELECT counter FROM ping_pong ORDER BY id DESC LIMIT 1"
        result = await database.fetch_val(query)
        return result if result is not None else 0
    except Exception as e:
        log.error("Error getting counter from database: %s", e)
        return 0

async def increment_counter_in_db():
    """Increment the counter in database and return the previous value."""
    try:
        # Get current counter
        current_counter = await get_counter_from_db()

        # Update with incremented value
        new_counter = current_counter + 1
        update_query = """
        UPDATE ping_pong SET counter = :counter, updated_at = CURRENT_TIMESTAMP
        WHERE id = (SELECT id FROM ping_pong ORDER BY id DESC LIMIT 1)
        """
        await database.execute(update_query, {"counter": new_counter})

        log.debug("Updated ping-pong counter to %d", new_counter)
        return current_counter
    except Exception as e:
        log.error("Error incrementing counter in database: %s", e)
        raise HTTPException(status_code=500, detail="Error updating counter in database")

# --- FastAPI app ---
app = FastAPI(title="ping-pong-app", version="1.0.0")

@app.on_event("startup")
async def startup_event():
    """Initialize the application on startup."""
    global USE_DATABASE
    setup_file_logging()

    try:
        await init_database()
        USE_DATABASE = True
        log.info("Database initialization successful - using PostgreSQL")
    except Exception as e:
        USE_DATABASE = False
        log.warning("Database initialization failed - falling back to file storage: %s", e)

    APP_HASH = generate_random_string(6)
    log.info("Ping-pong server started on port %d", FLASK_PORT)
    log.info("App instance hash: %s", APP_HASH)
    log.info("Storage mode: %s", "PostgreSQL" if USE_DATABASE else "File-based")

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up on application shutdown."""
    global USE_DATABASE
    if USE_DATABASE:
        try:
            await database.disconnect()
            log.info("Disconnected from database")
        except Exception as e:
            log.warning("Error disconnecting from database: %s", e)

@app.get('/pingpong')
async def get_status():
    """Endpoint to get the pingpong counter and increment it"""
    global PING_PONG_COUNTER, USE_DATABASE

    try:
        if USE_DATABASE:
            current_counter = await increment_counter_in_db()
        else:
            # Fallback to in-memory counter
            current_counter = PING_PONG_COUNTER
            PING_PONG_COUNTER += 1

        # Also write to file for backup/compatibility
        LOGS_DIR.mkdir(parents=True, exist_ok=True)
        try:
            with open(LOG_PATH, "w") as f:
                f.write(str(current_counter + 1))
        except Exception as e:
            log.warning("Error writing to backup log file %s: %s", LOG_PATH, e)

        return {
            "message": f"pong {current_counter}",
            "counter": current_counter,
            "storage": "database" if USE_DATABASE else "memory"
        }
    except Exception as e:
        log.error("Error in pingpong endpoint: %s", e)
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get('/pings')
async def get_pings():
    """Endpoint to get the current pingpong counter without incrementing"""
    global PING_PONG_COUNTER, USE_DATABASE

    try:
        if USE_DATABASE:
            current_counter = await get_counter_from_db()
        else:
            # Fallback to in-memory counter
            current_counter = PING_PONG_COUNTER

        return {
            "message": f"pong {current_counter}",
            "counter": current_counter,
            "storage": "database" if USE_DATABASE else "memory"
        }
    except Exception as e:
        log.error("Error in pings endpoint: %s", e)
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get('/health')
async def health_check():
    """Health check endpoint to verify database connectivity"""
    global USE_DATABASE

    health_status = {
        "status": "healthy",
        "storage_mode": "database" if USE_DATABASE else "memory",
        "database": "not_configured"
    }

    if USE_DATABASE:
        try:
            # Simple database connectivity check
            await database.fetch_val("SELECT 1")
            health_status["database"] = "connected"
        except Exception as e:
            log.error("Health check database query failed: %s", e)
            health_status["database"] = "disconnected"
            health_status["status"] = "degraded"

    return health_status

# For compatibility when running directly
if __name__ == '__main__':
    import uvicorn
    import asyncio

    async def setup():
        setup_file_logging()
        await init_database()
        APP_HASH = generate_random_string(6)
        log.info("Ping-pong server started on port %d", FLASK_PORT)
        log.info("App instance hash: %s", APP_HASH)

    # Run setup
    asyncio.run(setup())

    # Start the server
    uvicorn.run(app, host='0.0.0.0', port=FLASK_PORT)