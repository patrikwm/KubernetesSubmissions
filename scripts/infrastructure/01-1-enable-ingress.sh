#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

log_step "Enabling app routing (NGINX ingress) on cluster $AKS_NAME..."

# Enable app routing
log_info "Enabling app routing addon..."
az aks approuting enable \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME"

# Wait for pods to start
log_info "Waiting for ingress controller pods to start..."
sleep 15

# Wait for pods to be ready
log_info "Waiting for ingress controller pods to be ready..."
kubectl wait --for=condition=Ready pod \
    -l app.kubernetes.io/name=nginx \
    -n app-routing-system \
    --timeout=300s || log_warn "Some pods may still be starting..."

# Verify ingress class
log_info "Verifying ingress class..."
kubectl get ingressclass

echo ""
log_info "✅ App routing enabled successfully!"
echo ""
log_step "You can now deploy apps with ingress resources using:"
echo "  ingressClassName: webapprouting.kubernetes.azure.com"
echo ""
log_step "Next steps:"
echo "  cd ../apps"
echo "  ./deploy-postgres.sh"
echo "  ./deploy-ping-pong.sh"
echo ""
