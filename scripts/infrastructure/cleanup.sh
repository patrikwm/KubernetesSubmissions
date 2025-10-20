#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo ""
log_warn "⚠️  ⚠️  ⚠️  DANGER ZONE ⚠️  ⚠️  ⚠️"
echo ""
log_error "This will DELETE the entire AKS cluster and all resources!"
log_error "Cluster: $AKS_NAME"
log_error "Resource Group: $RESOURCE_GROUP"
echo ""
read -p "Type 'yes' to confirm deletion: " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    log_info "Cleanup cancelled"
    exit 0
fi

echo ""
log_step "Starting cleanup of AKS cluster $AKS_NAME..."

# Login to Azure
log_info "Logging into Azure..."
az login
az account set --subscription "$SUBSCRIPTION_ID"

# Get cluster credentials (ignore errors if cluster doesn't exist)
log_info "Getting cluster credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --overwrite-existing 2>/dev/null || log_warn "Could not get cluster credentials"

# Uninstall ALB Controller
log_info "Uninstalling ALB Controller..."
helm uninstall alb-controller -n default 2>/dev/null || log_warn "ALB Controller not found"
kubectl delete ns azure-alb-system 2>/dev/null || true
kubectl delete gatewayclass azure-alb-external 2>/dev/null || true

# Delete federated credential
log_info "Deleting federated credential..."
az identity federated-credential delete \
    --name "azure-alb-identity" \
    --identity-name "$IDENTITY_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --yes 2>/dev/null || log_warn "Federated credential not found"

# Get managed cluster resource group
mcResourceGroup=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --query "nodeResourceGroup" -o tsv 2>/dev/null || echo "")
mcResourceGroupId=$(az group show --name "$mcResourceGroup" --query id -otsv 2>/dev/null || echo "")
principalId=$(az identity show -g "$RESOURCE_GROUP" -n "$IDENTITY_RESOURCE_NAME" --query principalId -otsv 2>/dev/null || echo "")

# Remove role assignments
if [ -n "$principalId" ] && [ -n "$mcResourceGroupId" ]; then
    log_info "Removing role assignments..."
    az role assignment delete \
        --assignee-object-id "$principalId" \
        --scope "$mcResourceGroupId" \
        --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" 2>/dev/null || log_warn "Reader role assignment not found"

    # Try to find and delete any subnet role assignments
    CLUSTER_SUBNET_ID=$(az vmss list --resource-group "$mcResourceGroup" --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv 2>/dev/null || echo "")
    if [ -n "$CLUSTER_SUBNET_ID" ]; then
        VNET_RESOURCE_GROUP=$(az network vnet show --ids "$CLUSTER_SUBNET_ID" --query 'resourceGroup' -o tsv 2>/dev/null || echo "")
        VNET_NAME=$(az network vnet show --ids "$CLUSTER_SUBNET_ID" --query 'name' -o tsv 2>/dev/null || echo "")
        if [ -n "$VNET_RESOURCE_GROUP" ] && [ -n "$VNET_NAME" ]; then
            ALB_SUBNET_ID=$(az network vnet subnet show --name alb-subnet --resource-group "$VNET_RESOURCE_GROUP" --vnet-name "$VNET_NAME" --query 'id' -o tsv 2>/dev/null || echo "")
            if [ -n "$ALB_SUBNET_ID" ]; then
                az role assignment delete \
                    --assignee-object-id "$principalId" \
                    --scope "$ALB_SUBNET_ID" \
                    --role "4d97b98b-1d4f-4787-a291-c67834d212e7" 2>/dev/null || log_warn "Subnet role assignment not found"
            fi
        fi
    fi
fi

# Delete managed identity
log_info "Deleting managed identity..."
az identity delete \
    --resource-group "$RESOURCE_GROUP" \
    --name "$IDENTITY_RESOURCE_NAME" 2>/dev/null || log_warn "Identity not found"

# Delete AKS cluster
log_info "Deleting AKS cluster (running in background)..."
az aks delete \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --yes \
    --no-wait

echo ""
log_info "✅ Cleanup initiated!"
echo ""
log_step "What happens next:"
echo "  - Cluster deletion is running in background (takes ~5-10 minutes)"
echo "  - Azure will automatically clean up: $mcResourceGroup"
echo "  - You can check status with: az aks show -n $AKS_NAME -g $RESOURCE_GROUP"
echo ""
log_info "💰 Remember to verify deletion to avoid charges!"
echo ""
