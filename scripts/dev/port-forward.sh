#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Parse arguments
NAMESPACE="${1:-exercises}"
SERVICE="${2:-}"

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <namespace> <service-name> [local-port:remote-port]"
    echo ""
    echo "Examples:"
    echo "  $0 exercises ping-pong-svc 8080:80"
    echo "  $0 database postgres-svc 5432:5432"
    echo ""
    log_step "Available services:"
    echo ""
    echo "In namespace 'exercises':"
    kubectl get svc -n exercises 2>/dev/null || echo "  (namespace not found)"
    echo ""
    echo "In namespace 'database':"
    kubectl get svc -n database 2>/dev/null || echo "  (namespace not found)"
    exit 1
fi

PORT_MAPPING="${3:-8080:80}"

log_info "Setting up port-forward for $SERVICE in namespace $NAMESPACE"
log_info "Port mapping: $PORT_MAPPING (local:remote)"
echo ""
log_warn "Press Ctrl+C to stop port-forwarding"
echo ""

kubectl port-forward -n "$NAMESPACE" "svc/$SERVICE" "$PORT_MAPPING"
