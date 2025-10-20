#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

cd "$PROJECT_ROOT"

# Check if venv exists
if [ ! -d ".venv" ]; then
    log_error "Virtual environment not found!"
    echo "Run: ./setup-venv.sh"
    exit 1
fi

source .venv/bin/activate

log_step "Running tests for all applications..."
echo ""

# Ping-pong application
if [ -f "ping-pong_application/test_db.py" ]; then
    log_info "Testing ping-pong_application..."
    cd ping-pong_application
    python test_db.py || log_error "Ping-pong tests failed"
    cd ..
    echo ""
fi

# Todo-backend
if [ -f "todo-backend/test_db.py" ]; then
    log_info "Testing todo-backend..."
    cd todo-backend
    python test_db.py || log_error "Todo-backend tests failed"
    cd ..
    echo ""
fi

log_info "✅ Test run complete!"
echo ""
log_step "Note: Make sure services are running before testing database connections"
