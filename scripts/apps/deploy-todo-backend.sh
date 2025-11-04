#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NAMESPACE="exercises"
MANIFESTS_DIR="$PROJECT_ROOT/todo-backend/manifests"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

if [ "${1:-}" == "delete" ]; then
    log_info "Deleting todo-backend from namespace $NAMESPACE..."
    kubectl delete -f "$MANIFESTS_DIR" --ignore-not-found=true
    log_info "✅ Todo-backend deleted"
    exit 0
fi

log_step "Deploying todo-backend to namespace $NAMESPACE..."

# Check if postgres is running
log_info "Checking if postgres is deployed..."
if ! kubectl get namespace database &>/dev/null || ! kubectl get pod -n database -l app=postgres &>/dev/null; then
    log_warn "Postgres not found! Deploy it first:"
    echo "  ./deploy-postgres.sh"
    exit 1
fi

# Create namespace if it doesn't exist
log_info "Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests
log_info "Applying manifests..."
kubectl apply -f "$MANIFESTS_DIR"

log_info "Waiting for todo-backend to be ready..."
kubectl wait --for=condition=Ready pod -l app=todo-backend -n "$NAMESPACE" --timeout=300s

echo ""
log_info "✅ Todo-backend deployed successfully!"
echo ""
kubectl get pods,svc -n "$NAMESPACE" | grep todo-backend
echo ""
