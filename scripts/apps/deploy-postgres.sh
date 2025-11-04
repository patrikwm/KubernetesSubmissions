#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NAMESPACE="database"
MANIFESTS_DIR="$PROJECT_ROOT/postgres/manifests"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "${1:-}" == "delete" ]; then
    log_info "Deleting postgres from namespace $NAMESPACE..."
    kubectl delete -f "$MANIFESTS_DIR" --ignore-not-found=true
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    log_info "✅ Postgres deleted"
    exit 0
fi

log_info "Deploying postgres to namespace $NAMESPACE..."

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests
/opt/homebrew/bin/sops --decrypt postgres/manifests/secrets.enc.yaml | /usr/local/bin/kubectl apply -n $NAMESPACE -f -
/usr/local/bin/kubectl apply -n $NAMESPACE -f postgres/manifests/postgres-stset.yaml

log_info "Waiting for postgres to be ready..."
kubectl wait --for=condition=Ready pod -l app=postgres -n "$NAMESPACE" --timeout=300s

echo ""
log_info "✅ Postgres deployed successfully!"
echo ""
kubectl get pods,svc -n "$NAMESPACE"
echo ""
log_info "Connection details:"
echo "  Host: postgres-svc.database"
echo "  Port: 5432"
echo "  Database: postgres"
echo ""
