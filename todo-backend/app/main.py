# app/main.py
import os
import logging
from datetime import datetime
from typing import List
from uuid import uuid4, UUID

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import databases
import asyncpg

# ----- Logging -----
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                    format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("todo-backend")

# ----- PostgreSQL Configuration -----
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", "postgres-svc")
POSTGRES_PORT = int(os.environ.get("POSTGRES_PORT", "5432"))
POSTGRES_DB = os.environ.get("POSTGRES_DB", "postgres")
POSTGRES_USER = os.environ.get("POSTGRES_USER", "postgres")
POSTGRES_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "example")

DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"

# ----- Database -----
database = databases.Database(DATABASE_URL)
USE_DATABASE = True  # Flag to determine if database is available

# ----- Models -----
class TodoIn(BaseModel):
    text: str = Field(min_length=1, max_length=500)
    done: bool = False

class TodoOut(TodoIn):
    id: UUID
    created_at: datetime

# ----- Fallback in-memory store -----
class TodoStore:
    def __init__(self):
        self._items: list[TodoOut] = []

    def list(self) -> List[TodoOut]:
        return self._items

    def create(self, todo_in: TodoIn) -> TodoOut:
        item = TodoOut(id=uuid4(), created_at=datetime.utcnow(), **todo_in.model_dump())
        self._items.append(item)
        return item

fallback_store = TodoStore()

# ----- Database Functions -----
async def init_database():
    """Initialize the database connection and create tables if needed."""
    try:
        log.info(f"Attempting to connect to database: {DATABASE_URL.replace(POSTGRES_PASSWORD, '***')}")
        await database.connect()
        log.info("Connected to PostgreSQL database")

        # Test basic connectivity
        test_result = await database.fetch_val("SELECT 1")
        log.info(f"Database connectivity test successful: {test_result}")

        # Create the todos table if it doesn't exist
        query = """
        CREATE TABLE IF NOT EXISTS todos (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            text VARCHAR(500) NOT NULL,
            done BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        """
        await database.execute(query)
        log.info("Todos table created or already exists")

        # Check current records count
        count = await database.fetch_val("SELECT COUNT(*) FROM todos")
        log.info(f"Current records in todos table: {count}")

    except Exception as e:
        log.error("Error initializing database: %s", e)
        log.error(f"Database URL (sanitized): {DATABASE_URL.replace(POSTGRES_PASSWORD, '***')}")
        raise

async def get_todos_from_db() -> List[TodoOut]:
    """Get all todos from database."""
    try:
        query = "SELECT id, text, done, created_at FROM todos ORDER BY created_at DESC"
        rows = await database.fetch_all(query)
        return [
            TodoOut(
                id=row["id"],
                text=row["text"],
                done=row["done"],
                created_at=row["created_at"]
            )
            for row in rows
        ]
    except Exception as e:
        log.error("Error getting todos from database: %s", e)
        return []

async def create_todo_in_db(todo_in: TodoIn) -> TodoOut:
    """Create a new todo in database."""
    try:
        todo_id = uuid4()
        created_at = datetime.utcnow()

        query = """
        INSERT INTO todos (id, text, done, created_at)
        VALUES (:id, :text, :done, :created_at)
        """
        await database.execute(query, {
            "id": todo_id,
            "text": todo_in.text,
            "done": todo_in.done,
            "created_at": created_at
        })

        log.info(f"Created todo with id: {todo_id}")
        return TodoOut(
            id=todo_id,
            text=todo_in.text,
            done=todo_in.done,
            created_at=created_at
        )
    except Exception as e:
        log.error("Error creating todo in database: %s", e)
        raise HTTPException(status_code=500, detail="Error creating todo in database")

# ----- App -----
app = FastAPI(title="todo-backend", version="0.1.0")

CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")
# CORS for SPA (adjust allowed origins as needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,           # tighten later (e.g., ["https://todo.example.com"])
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    """Initialize the application on startup."""
    global USE_DATABASE

    try:
        await init_database()
        USE_DATABASE = True
        log.info("Database initialization successful - using PostgreSQL")
    except Exception as e:
        USE_DATABASE = False
        log.warning("Database initialization failed - falling back to in-memory storage: %s", e)

    log.info("Todo-backend server started")
    log.info("Storage mode: %s", "PostgreSQL" if USE_DATABASE else "In-memory")

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

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.get("/readyz")
async def readyz():
    """Readiness check including database connectivity."""
    global USE_DATABASE

    health_status = {
        "ready": True,
        "storage_mode": "database" if USE_DATABASE else "memory",
        "database": "not_configured"
    }

    if USE_DATABASE:
        try:
            await database.fetch_val("SELECT 1")
            health_status["database"] = "connected"
        except Exception as e:
            log.error("Readiness check database query failed: %s", e)
            health_status["database"] = "disconnected"
            health_status["ready"] = False

    return health_status

@app.get("/todos", response_model=List[TodoOut])
async def list_todos():
    """Get all todos."""
    global USE_DATABASE

    try:
        if USE_DATABASE:
            todos = await get_todos_from_db()
        else:
            todos = fallback_store.list()

        return todos
    except Exception as e:
        log.error("Error listing todos: %s", e)
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/todos", response_model=TodoOut, status_code=201)
async def create_todo(todo: TodoIn):
    """Create a new todo."""
    global USE_DATABASE

    try:
        if USE_DATABASE:
            new_todo = await create_todo_in_db(todo)
        else:
            new_todo = fallback_store.create(todo)

        return new_todo
    except Exception as e:
        log.error("Error creating todo: %s", e)
        raise HTTPException(status_code=500, detail="Internal server error")
