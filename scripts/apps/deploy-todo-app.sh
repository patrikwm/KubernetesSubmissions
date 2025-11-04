#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NAMESPACE="exercises"
MANIFESTS_DIR="$PROJECT_ROOT/todo-app/manifests"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

if [ "${1:-}" == "delete" ]; then
    log_info "Deleting todo-app from namespace $NAMESPACE..."
    kubectl delete -f "$MANIFESTS_DIR" --ignore-not-found=true
    log_info "✅ Todo-app deleted"
    exit 0
fi

log_step "Deploying todo-app to namespace $NAMESPACE..."

# Create namespace if it doesn't exist
log_info "Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests
log_info "Applying manifests..."
kubectl apply -f "$MANIFESTS_DIR"

log_info "Waiting for todo-app to be ready..."
kubectl wait --for=condition=Ready pod -l app=todo-app -n "$NAMESPACE" --timeout=300s

echo ""
log_info "✅ Todo-app deployed successfully!"
echo ""
kubectl get pods,svc,ingress -n "$NAMESPACE" | grep todo

# Get ingress IP
echo ""
log_info "Waiting for ingress IP assignment..."
sleep 10

INGRESS_IP=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{.items[?(@.metadata.name=="todo-app-ingress")].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

echo ""
if [ -n "$INGRESS_IP" ]; then
    log_info "✅ App available at:"
    echo "  http://$INGRESS_IP/"
    echo ""
    log_step "Test with:"
    echo "  curl http://$INGRESS_IP/"
else
    log_warn "Ingress IP not yet assigned. Check with:"
    echo "  kubectl get ingress -n $NAMESPACE --watch"
fi
echo ""
