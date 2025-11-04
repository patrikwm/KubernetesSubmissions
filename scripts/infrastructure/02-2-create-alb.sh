#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

log_step "Configuring ALB subnet for Application Gateway for Containers..."
echo ""

# Display what will be configured
log_info "📋 Configuration to be applied:"
echo ""
echo "  Azure Resources:"
echo "    • ALB Subnet: $ALB_SUBNET_NAME"
echo "      - VNet: $VNET_NAME"
echo "      - Address Prefix: $ALB_SUBNET_CIDR"
echo "      - Should already exist from network setup"
echo ""
echo "    • Role Assignment:"
echo "      - Role: Network Contributor"
echo "      - Identity: $IDENTITY_RESOURCE_NAME"
echo "      - Scope: ALB subnet"
echo ""

# Verify network exists
log_info "Verifying network infrastructure..."
if ! az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" &>/dev/null; then
    log_error "VNet $VNET_NAME not found!"
    echo ""
    log_warn "Please run ./00-create-network.sh first"
    exit 1
fi

# Get ALB subnet ID
ALB_SUBNET_ID=$(az network vnet subnet show \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$ALB_SUBNET_NAME" \
    --query id -o tsv 2>/dev/null || echo "NOT_FOUND")

if [ "$ALB_SUBNET_ID" = "NOT_FOUND" ]; then
    log_error "ALB subnet $ALB_SUBNET_NAME not found in VNet $VNET_NAME!"
    echo ""
    log_warn "Please run ./00-create-network.sh first"
    exit 1
fi

log_info "Found ALB subnet:"
log_info "  • Name: $ALB_SUBNET_NAME"
log_info "  • Address: $ALB_SUBNET_CIDR"
log_info "  • ID: $ALB_SUBNET_ID"

# Verify delegation
DELEGATION=$(az network vnet subnet show \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$ALB_SUBNET_NAME" \
    --query "delegations[0].serviceName" -o tsv 2>/dev/null || echo "none")

if [ "$DELEGATION" = "Microsoft.ServiceNetworking/trafficControllers" ]; then
    log_info "  • Delegation: ✓ Properly delegated"
else
    log_error "ALB subnet is not properly delegated!"
    log_warn "Expected: Microsoft.ServiceNetworking/trafficControllers"
    log_warn "Got: $DELEGATION"
    echo ""
    log_warn "Run ./00-create-network.sh to fix delegation"
    exit 1
fi
echo ""

# Assign Network Contributor role to the managed identity on the ALB subnet
log_info "Assigning Network Contributor role to identity on ALB subnet..."
principalId="$(az identity show -g "$RESOURCE_GROUP" -n "$IDENTITY_RESOURCE_NAME" --query principalId -otsv)"

az role assignment create \
    --assignee-object-id "$principalId" \
    --assignee-principal-type ServicePrincipal \
    --scope "$ALB_SUBNET_ID" \
    --role "4d97b98b-1d4f-4787-a291-c67834d212e7" 2>/dev/null || log_info "Network Contributor role assignment already exists"

echo ""
log_info "✅ ALB subnet configured successfully!"
echo ""
log_info "📝 Network Topology:"
echo "    VNet: $VNET_NAME ($VNET_CIDR)"
echo "    ├── AKS Subnet: $AKS_SUBNET_NAME ($AKS_SUBNET_CIDR) ← Nodes & pods"
echo "    └── ALB Subnet: $ALB_SUBNET_NAME ($ALB_SUBNET_CIDR) ← Application Gateway ✓"
echo ""
log_info "📝 Subnet Details:"
echo "    • Subnet ID: $ALB_SUBNET_ID"
echo "    • Delegation: Microsoft.ServiceNetworking/trafficControllers ✓"
echo "    • RBAC: Network Contributor assigned to $IDENTITY_RESOURCE_NAME ✓"
echo ""
log_info "📋 Next Steps - Deploy using Managed ALB (Recommended):"
echo ""
echo "    1. Create a namespace for ALB infrastructure:"
echo "       kubectl create namespace alb-infra"
echo ""
echo "    2. Create ApplicationLoadBalancer resource (save as alb.yaml):"
echo ""
echo "       apiVersion: alb.networking.azure.io/v1"
echo "       kind: ApplicationLoadBalancer"
echo "       metadata:"
echo "         name: alb-gateway"
echo "         namespace: alb-infra"
echo "       spec:"
echo "         associations:"
echo "         - $ALB_SUBNET_ID"
echo ""
echo "    3. Apply it:"
echo "       kubectl apply -f alb.yaml"
echo ""
echo "    4. Create your Gateway (save as gateway.yaml):"
echo ""
echo "       apiVersion: gateway.networking.k8s.io/v1"
echo "       kind: Gateway"
echo "       metadata:"
echo "         name: gateway-01"
echo "         namespace: default"
echo "       spec:"
echo "         gatewayClassName: azure-alb-external"
echo "         listeners:"
echo "         - name: http"
echo "           protocol: HTTP"
echo "           port: 80"
echo ""
echo "    5. Create HTTPRoute for your services"
echo ""
echo "    Note: The ALB controller will automatically create the Azure ALB resource"
echo "          and configure it based on your Gateway and HTTPRoute manifests."
echo ""
