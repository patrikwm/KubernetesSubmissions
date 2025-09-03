# app/main.py
from __future__ import annotations
import os, base64, logging
from pathlib import Path
from datetime import datetime, timezone
from typing import Optional, List

import httpx
from fastapi import FastAPI, BackgroundTasks, Form, status, Request
from fastapi.responses import HTMLResponse, RedirectResponse, FileResponse, Response

# ---------- Config ----------
DATA_ROOT = Path(os.environ.get("DATA_ROOT", "/data"))  # mount a volume here
LOG_DIR = DATA_ROOT / "logs"
IMG_DIR = DATA_ROOT / "images"
IMG_PATH = IMG_DIR / "image.jpg"
TS_PATH  = IMG_DIR / ".ts"

MAX_AGE_SEC = int(os.environ.get("MAX_AGE_SEC", "600"))  # 10 minutes
PICSUM_URL = os.environ.get("PICSUM_URL", "https://picsum.photos/1200")
TODO_BACKEND_URL = os.environ.get("TODO_BACKEND_URL", "http://127.0.0.1:8000").rstrip("/")

# ---------- Logging ----------
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("todo-app")

def setup_file_logging() -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    fh = logging.FileHandler(LOG_DIR / "todo-app.log", encoding="utf-8")
    fh.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
    log.addHandler(fh)
    log.info("File logging -> %s", LOG_DIR / "todo-app.log")

# ---------- Image cache helpers ----------
# Return current time.
def _now() -> datetime: return datetime.now(timezone.utc)

def _age_seconds() -> Optional[float]:
    # Check if Timestamp exists
    if not TS_PATH.exists():
        return None
    # Since it exists return number of seconds it has existed.
    try:
        ts = datetime.fromisoformat(TS_PATH.read_text().strip())
        return (_now() - ts).total_seconds()
    # On failure throw exception.
    except Exception:
        return None

def _ensure_image_exists() -> None:
    # Verify that the image exists in the IMG_PATH
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    if not IMG_PATH.exists():
        _download_new_image()

def _atomic_write(path: Path, data: bytes) -> None:
    # Make sure users dont get half written file.
    # Creates temp file, writes bytes to temp file
    # Replace old image with new image
    tmp = path.with_suffix(path.suffix + ".part")
    tmp.write_bytes(data)
    os.replace(tmp, path)  # atomic on POSIX

def _download_new_image() -> None:
    # downloads new image
    try:
        log.info("Downloading new image from %s", PICSUM_URL)
        with httpx.Client(timeout=8.0, follow_redirects=True) as client:
            r = client.get(PICSUM_URL)
            r.raise_for_status()
            IMG_DIR.mkdir(parents=True, exist_ok=True)
            _atomic_write(IMG_PATH, r.content)
            TS_PATH.write_text(_now().isoformat())
        log.info("New image saved")
    except Exception as e:
        log.warning("Failed to refresh image, serving current one: %s", e)

# ---------- Todo helpers ----------
_LOCAL_TODOS: List[dict] = [
    {"text": "Learn JavaScript", "done": False},
    {"text": "Learn React", "done": False},
    {"text": "Build a project", "done": True},
]

async def _fetch_todos() -> List[dict]:
    if not TODO_BACKEND_URL:
        return _LOCAL_TODOS
    try:
        async with httpx.AsyncClient(timeout=4.0) as c:
            r = await c.get(f"{TODO_BACKEND_URL}/todos")
            r.raise_for_status()
            return r.json()
    except Exception as e:
        log.warning("Backend /todos failed: %s", e)
        return _LOCAL_TODOS

async def _create_todo(text: str) -> None:
    text = text.strip()[:140]
    if not text:
        return
    if not TODO_BACKEND_URL:
        _LOCAL_TODOS.append({"text": text, "done": False})
        return
    try:
        async with httpx.AsyncClient(timeout=4.0) as c:
            await c.post(f"{TODO_BACKEND_URL}/todos", json={"text": text, "done": False})
    except Exception as e:
        log.warning("Backend create failed, keeping local only: %s", e)
        _LOCAL_TODOS.append({"text": text, "done": False})

# ---------- FastAPI app ----------
app = FastAPI(title="todo-app", version="1.0.0")

@app.on_event("startup")
def _startup() -> None:
    setup_file_logging()
    _ensure_image_exists()
    log.info("todo-app started")

@app.get("/image")
def get_image(request: Request):
    _ensure_image_exists()

    # Use your timestamp file as a cheap version/ETag
    ts = TS_PATH.read_text().strip() if TS_PATH.exists() else "0"
    etag = f'W/"{ts}"'  # weak ETag is fine

    if request.headers.get("if-none-match") == etag:
        # Browser/CDN can keep its cached copy
        return Response(status_code=304, headers={
            "ETag": etag,
            "Cache-Control": "public, max-age=600, stale-while-revalidate=60",
        })

    # Let Starlette set Last-Modified from file mtime; we add ETag & Cache-Control
    return FileResponse(
        IMG_PATH,
        media_type="image/jpeg",
        headers={
            "ETag": etag,
            "Cache-Control": "public, max-age=600, stale-while-revalidate=60",
        },
    )

@app.get("/", response_class=HTMLResponse)
async def home(background: BackgroundTasks) -> str:
    _ensure_image_exists()

    age = _age_seconds()
    if age is None or age >= MAX_AGE_SEC:
        background.add_task(_download_new_image)

    ver = TS_PATH.read_text().strip() if TS_PATH.exists() else "0"
    img_src = f"/image?ver={ver}"   # busts caches when the TS changes
    todos = await _fetch_todos()

    return f"""
    <h1>The project App</h1>
    <img src="{img_src}" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>
      {''.join(f"<li>{'✅ ' if t.get('done') else '⬜️ '}{t.get('text','')}</li>" for t in todos)}
    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
    """

@app.post("/", response_class=HTMLResponse)
async def create(todo: str = Form(...)) -> RedirectResponse:
    await _create_todo(todo)
    # PRG pattern
    return RedirectResponse("/", status_code=status.HTTP_303_SEE_OTHER)

@app.get("/_shutdown")
def shutdown():
    os._exit(0)