#!/usr/bin/env bash
set -euo pipefail

echo "[*] Setting up Python virtual environment in .venv"

# Create venv if missing
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  echo "[+] Created new venv"
else
  echo "[+] Reusing existing venv"
fi

# Activate it (works in zsh/bash)
# shellcheck disable=SC1091
source .venv/bin/activate

echo "[*] Installing dependencies..."
pip install --upgrade pip

pip install -r log_output/requirements.txt
pip install -r ping-pong_application/requirements.txt
pip install -r todo-app/requirements.txt
pip install -r todo-backend/requirements.txt

echo "[✓] Development environment ready. Run 'source .venv/bin/activate' to use it."

export DATA_ROOT=./shared