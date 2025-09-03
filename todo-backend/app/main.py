# app/main.py
from datetime import datetime
from typing import List
from uuid import uuid4, UUID

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ----- Models -----
class TodoIn(BaseModel):
    text: str = Field(min_length=1, max_length=500)
    done: bool = False

class TodoOut(TodoIn):
    id: UUID
    created_at: datetime

# ----- Simple in-memory store (process-local) -----
class TodoStore:
    def __init__(self):
        self._items: list[TodoOut] = []

    def list(self) -> List[TodoOut]:
        return self._items

    def create(self, todo_in: TodoIn) -> TodoOut:
        item = TodoOut(id=uuid4(), created_at=datetime.utcnow(), **todo_in.model_dump())
        self._items.append(item)
        return item

store = TodoStore()

# ----- App -----
app = FastAPI(title="todo-backend", version="0.1.0")

# CORS for SPA (adjust allowed origins as needed)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],           # tighten later (e.g., ["https://todo.example.com"])
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

@app.get("/healthz")
def healthz():
    return {"status": "ok"}

@app.get("/readyz")
def readyz():
    # In real life, check DB connection, queues, etc.
    return {"ready": True}

@app.get("/todos", response_model=List[TodoOut])
def list_todos():
    return store.list()

@app.post("/todos", response_model=TodoOut, status_code=201)
def create_todo(todo: TodoIn):
    return store.create(todo)
