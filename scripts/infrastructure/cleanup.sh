#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo ""
log_warn "⚠️  ⚠️  ⚠️  DANGER ZONE ⚠️  ⚠️  ⚠️"
echo ""
log_error "This will DELETE the entire AKS cluster and all associated resources!"
log_error "Cluster: $AKS_NAME"
log_error "Resource Group: $RESOURCE_GROUP"
log_error "Location: $LOCATION"
echo ""
log_warn "Resources that will be deleted:"
echo "  • AKS Cluster and all Kubernetes workloads"
echo "  • Managed resource group (nodes, disks, IPs, etc.)"
echo "  • Managed Identity: $IDENTITY_RESOURCE_NAME"
echo "  • All role assignments"
echo "  • Federated identity credentials"
echo ""
log_info "Note: VNet and subnets will NOT be deleted (can be reused)"
echo ""
read -p "Type 'DELETE' to confirm: " -r
if [[ ! $REPLY =~ ^DELETE$ ]]; then
    log_info "Cleanup cancelled"
    exit 0
fi

echo ""
log_step "Starting cleanup process..."
echo ""

# Login to Azure (only if not already logged in)
log_info "Checking Azure login status..."
if ! az account show --only-show-errors &>/dev/null; then
    log_info "Logging into Azure..."
    az login
fi
az account set --subscription "$SUBSCRIPTION_ID" --only-show-errors

# Get cluster info before deletion (for cleanup references)
log_info "Gathering cluster information..."
mcResourceGroup=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --query "nodeResourceGroup" -o tsv 2>/dev/null || echo "")
if [ -n "$mcResourceGroup" ]; then
    log_info "Found managed resource group: $mcResourceGroup"
    mcResourceGroupId=$(az group show --name "$mcResourceGroup" --query id -otsv 2>/dev/null || echo "")
else
    log_warn "Cluster not found or already deleted"
    mcResourceGroupId=""
fi

# Get managed identity info
principalId=$(az identity show -g "$RESOURCE_GROUP" -n "$IDENTITY_RESOURCE_NAME" --query principalId -otsv 2>/dev/null || echo "")

# --- Clean up IAM and Identity (these won't auto-delete with cluster) ---

# Delete federated credential
if [ -n "$principalId" ]; then
    log_info "Deleting federated identity credential..."
    az identity federated-credential delete \
        --name "azure-alb-identity" \
        --identity-name "$IDENTITY_RESOURCE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --yes 2>/dev/null || log_warn "Federated credential not found"
fi

# Remove role assignments
if [ -n "$principalId" ]; then
    log_info "Removing role assignments..."

    # Reader role on managed resource group
    if [ -n "$mcResourceGroupId" ]; then
        az role assignment delete \
            --assignee-object-id "$principalId" \
            --scope "$mcResourceGroupId" \
            --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" 2>/dev/null || log_warn "Reader role not found"

        # AppGW Configuration Manager role on managed resource group
        az role assignment delete \
            --assignee-object-id "$principalId" \
            --scope "$mcResourceGroupId" \
            --role "fbc52c3f-28ad-4303-a892-8a056630b8f1" 2>/dev/null || log_warn "AppGW Configuration Manager role not found"
    fi

    # Network Contributor on ALB subnet (if exists)
    ALB_SUBNET_ID=$(az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --name "$ALB_SUBNET_NAME" \
        --query id -o tsv 2>/dev/null || echo "")

    if [ -n "$ALB_SUBNET_ID" ]; then
        az role assignment delete \
            --assignee-object-id "$principalId" \
            --scope "$ALB_SUBNET_ID" \
            --role "4d97b98b-1d4f-4787-a291-c67834d212e7" 2>/dev/null || log_warn "Network Contributor role not found"
    fi
fi

# Delete managed identity
log_info "Deleting managed identity $IDENTITY_RESOURCE_NAME..."
az identity delete \
    --resource-group "$RESOURCE_GROUP" \
    --name "$IDENTITY_RESOURCE_NAME" 2>/dev/null || log_warn "Identity not found"

# --- Delete AKS cluster (this will delete all Kubernetes resources) ---

log_info "Deleting AKS cluster $AKS_NAME..."
log_warn "This will also delete all pods, services, ingresses, volumes, etc."
az aks delete \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --yes \
    --no-wait \
    --only-show-errors

echo ""
log_info "✅ Cleanup initiated!"
echo ""
log_step "What's happening:"
echo "  1. ✅ Managed identity deleted"
echo "  2. ✅ Role assignments removed"
echo "  3. ✅ Federated credential deleted"
echo "  4. ⏳ AKS cluster deletion running in background (~5-10 minutes)"
echo ""
log_step "Azure will automatically clean up:"
echo "  • All Kubernetes resources (pods, services, deployments, etc.)"
echo "  • Managed resource group: $mcResourceGroup"
echo "  • Node VMs, disks, network interfaces"
echo "  • Load balancers and public IPs"
echo ""
log_step "Resources preserved (can be reused):"
echo "  • VNet: $VNET_NAME ($VNET_CIDR)"
echo "  • AKS Subnet: $AKS_SUBNET_NAME ($AKS_SUBNET_CIDR)"
echo "  • ALB Subnet: $ALB_SUBNET_NAME ($ALB_SUBNET_CIDR)"
echo ""
log_info "Check deletion status with:"
echo "  az aks show -n $AKS_NAME -g $RESOURCE_GROUP --only-show-errors"
echo ""
log_warn "💰 Verify complete deletion to avoid unexpected charges!"
echo "  az aks list -g $RESOURCE_GROUP -o table"
echo ""
