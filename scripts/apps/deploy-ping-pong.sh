#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NAMESPACE="exercises"
MANIFESTS_DIR="$PROJECT_ROOT/ping-pong_application/manifests"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

if [ "${1:-}" == "delete" ]; then
    log_info "Deleting ping-pong app from namespace $NAMESPACE..."
    kubectl delete -f "$MANIFESTS_DIR/deployment.yaml" --ignore-not-found=true
    kubectl delete -f "$MANIFESTS_DIR/service.yaml" --ignore-not-found=true
    kubectl delete -f "$MANIFESTS_DIR/ingress.yaml" --ignore-not-found=true
    kubectl delete -f "$MANIFESTS_DIR/secret.enc.yaml" --ignore-not-found=true 2>/dev/null || true
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    log_info "✅ Ping-pong app deleted"
    exit 0
fi

log_step "Deploying ping-pong app to namespace $NAMESPACE..."

# Check if postgres is running
log_info "Checking if postgres is deployed..."
if ! kubectl get namespace database &>/dev/null || ! kubectl get pod -n database -l app=postgres &>/dev/null; then
    log_warn "Postgres not found! Deploy it first:"
    echo "  ./deploy-postgres.sh"
    exit 1
fi

# Create namespace
log_info "Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests (skip gateway and route files)
log_info "Applying secrets..."
/opt/homebrew/bin/sops --decrypt ping-pong_application/manifests/secret.enc.yaml | /usr/local/bin/kubectl delete -n $NAMESPACE -f -

log_info "Applying deployment..."
kubectl apply -f "$MANIFESTS_DIR/deployment.yaml"

log_info "Applying service..."
kubectl apply -f "$MANIFESTS_DIR/service.yaml"

#log_info "Applying ingress..."
#kubectl apply -f "$MANIFESTS_DIR/ingress.yaml"

log_info "Waiting for ping-pong to be ready..."
kubectl wait --for=condition=Ready pod -l app=pingpong -n "$NAMESPACE" --timeout=300s

echo ""
log_info "✅ Ping-pong app deployed successfully!"
echo ""
kubectl get pods,svc,ingress -n "$NAMESPACE"

# Get ingress IP
echo ""
log_info "Waiting for ingress IP assignment..."
sleep 10

INGRESS_IP=""
for i in {1..30}; do
    INGRESS_IP=$(kubectl get ingress -n "$NAMESPACE" ping-pong-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$INGRESS_IP" ]; then
        break
    fi
    sleep 2
done

echo ""
if [ -n "$INGRESS_IP" ]; then
    log_info "✅ App available at:"
    echo "  http://$INGRESS_IP/pingpong"
    echo "  http://$INGRESS_IP/pings"
    echo ""
    log_step "Test with:"
    echo "  curl http://$INGRESS_IP/pingpong"
    echo "  curl http://$INGRESS_IP/pings"
else
    log_warn "Ingress IP not yet assigned. Check with:"
    echo "  kubectl get ingress -n $NAMESPACE --watch"
fi
echo ""
