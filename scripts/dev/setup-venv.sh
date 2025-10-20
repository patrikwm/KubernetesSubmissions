#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

log_step "Setting up Python virtual environment in .venv"

# Create venv if missing
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  log_info "Created new venv"
else
  log_info "Reusing existing venv"
fi

# Activate it
source .venv/bin/activate

log_info "Installing dependencies..."
pip install --upgrade pip --quiet

log_info "Installing log_output dependencies..."
pip install -r log_output/requirements.txt --quiet

log_info "Installing ping-pong_application dependencies..."
pip install -r ping-pong_application/requirements.txt --quiet

log_info "Installing todo-app dependencies..."
pip install -r todo-app/requirements.txt --quiet

log_info "Installing todo-backend dependencies..."
pip install -r todo-backend/requirements.txt --quiet

echo ""
log_info "✅ Development environment ready!"
echo ""
log_step "To activate the virtual environment, run:"
echo "  source .venv/bin/activate"
echo ""
log_step "Set shared data directory:"
echo "  export DATA_ROOT=./shared"
echo ""
log_step "Run an app locally:"
echo "  cd ping-pong_application"
echo "  python -m app.main"
echo ""
