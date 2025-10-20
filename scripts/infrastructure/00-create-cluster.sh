#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

log_step "Creating AKS cluster $AKS_NAME in resource group $RESOURCE_GROUP..."
echo ""

# Verify network exists
log_info "Verifying network infrastructure..."
if ! az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" &>/dev/null; then
    log_error "VNet $VNET_NAME not found!"
    echo ""
    log_warn "Please run ./00-create-network.sh first to create the network infrastructure"
    exit 1
fi

# Get AKS subnet ID
AKS_SUBNET_ID=$(az network vnet subnet show \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$AKS_SUBNET_NAME" \
    --query id -o tsv)

log_info "Using existing network:"
log_info "  • VNet: $VNET_NAME ($VNET_CIDR)"
log_info "  • AKS Subnet: $AKS_SUBNET_NAME ($AKS_SUBNET_CIDR)"
log_info "  • Subnet ID: $AKS_SUBNET_ID"
echo ""

# Login to Azure
log_info "Logging into Azure..."
az login
az account set --subscription "$SUBSCRIPTION_ID"

# Register required resource providers
log_info "Registering Azure resource providers..."
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking

# Create resource group if it doesn't exist
log_info "Ensuring resource group exists..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" 2>/dev/null || true

# Create AKS cluster
log_info "Creating AKS cluster (this takes ~5-10 minutes)..."
log_info "Using location: $LOCATION (required for ALB support)"
az aks create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --location "$LOCATION" \
    --vnet-subnet-id "$AKS_SUBNET_ID" \
    --node-count 3 \
    --node-vm-size Standard_B2s \
    --node-osdisk-size 32 \
    --node-osdisk-type Managed \
    --os-sku Ubuntu \
    --tier free \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --network-plugin azure \
    --enable-oidc-issuer \
    --enable-workload-identity

# Get credentials
log_info "Getting cluster credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --overwrite-existing

# Verify cluster
log_info "Verifying cluster..."
kubectl cluster-info
kubectl get nodes

echo ""
log_info "✅ Cluster created successfully!"
echo ""
log_step "Next steps:"
echo "  1. Run ./02-1-enable-alb.sh to install ALB Controller"
echo "  2. Then deploy your applications using Gateway and HTTPRoute"
echo ""
