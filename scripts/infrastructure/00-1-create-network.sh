#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

log_step "Creating network infrastructure for AKS and ALB..."
echo ""

# Display what will be created
log_info "📋 Network resources to be created:"
echo ""
echo "  Virtual Network:"
echo "    • Name: $VNET_NAME"
echo "    • Resource Group: $RESOURCE_GROUP"
echo "    • Location: $LOCATION"
echo "    • Address Space: $VNET_CIDR (/15 = 131,072 IPs)"
echo ""
echo "  AKS Subnet:"
echo "    • Name: $AKS_SUBNET_NAME"
echo "    • Address Prefix: $AKS_SUBNET_CIDR (/24 = 256 IPs)"
echo "    • Purpose: AKS nodes and pods (Azure CNI)"
echo ""
echo "  ALB Subnet:"
echo "    • Name: $ALB_SUBNET_NAME"
echo "    • Address Prefix: $ALB_SUBNET_CIDR (/24 = 256 IPs)"
echo "    • Delegation: Microsoft.ServiceNetworking/trafficControllers"
echo "    • Purpose: Application Gateway for Containers"
echo ""
log_info "Network Topology:"
echo ""
echo "    $VNET_NAME ($VNET_CIDR)"
echo "    ├── $AKS_SUBNET_NAME ($AKS_SUBNET_CIDR) ← AKS nodes & pods"
echo "    └── $ALB_SUBNET_NAME ($ALB_SUBNET_CIDR) ← Application Gateway"
echo ""

# Create resource group if it doesn't exist
log_info "Ensuring resource group exists..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --only-show-errors 2>/dev/null || log_info "Resource group already exists"

# Check if VNet already exists
if az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" --only-show-errors &>/dev/null; then
    log_info "VNet $VNET_NAME already exists"

    # Verify address space (additive, don't replace)
    EXISTING_PREFIXES=$(az network vnet show -g "$RESOURCE_GROUP" -n "$VNET_NAME" --query "addressSpace.addressPrefixes" -o tsv --only-show-errors | tr '\t' '\n')

    if ! grep -q "^$VNET_CIDR$" <<< "$EXISTING_PREFIXES"; then
        log_warn "VNet missing required address prefix: $VNET_CIDR"
        log_warn "Current prefixes:"
        echo "$EXISTING_PREFIXES" | sed 's/^/      - /'
        read -p "Add $VNET_CIDR to VNet address space? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Adding $VNET_CIDR to VNet address space (additive)..."
            az network vnet update \
                --resource-group "$RESOURCE_GROUP" \
                --name "$VNET_NAME" \
                --add addressSpace.addressPrefixes "$VNET_CIDR" \
                --only-show-errors
            log_info "VNet updated ✓"
        else
            log_warn "Keeping existing VNet configuration - may cause subnet creation to fail!"
        fi
    else
        log_info "VNet already has correct address space ✓"
    fi
else
    # Create VNet
    log_info "Creating Virtual Network $VNET_NAME..."
    az network vnet create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VNET_NAME" \
        --location "$LOCATION" \
        --address-prefixes "$VNET_CIDR" \
        --only-show-errors
    log_info "VNet created ✓"
fi

# Create or verify AKS subnet
if az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$AKS_SUBNET_NAME" --only-show-errors &>/dev/null; then
    log_info "AKS subnet $AKS_SUBNET_NAME already exists"
else
    log_info "Creating AKS subnet $AKS_SUBNET_NAME..."
    az network vnet subnet create \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --name "$AKS_SUBNET_NAME" \
        --address-prefixes "$AKS_SUBNET_CIDR" \
        --only-show-errors
    log_info "AKS subnet created ✓"
fi

# Create or verify ALB subnet with delegation
if az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$ALB_SUBNET_NAME" --only-show-errors &>/dev/null; then
    log_info "ALB subnet $ALB_SUBNET_NAME already exists"

    # Verify delegation
    DELEGATION=$(az network vnet subnet show \
        -g "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        -n "$ALB_SUBNET_NAME" \
        --query "delegations[0].serviceName" -o tsv --only-show-errors 2>/dev/null || echo "none")

    if [ "$DELEGATION" != "Microsoft.ServiceNetworking/trafficControllers" ]; then
        log_warn "ALB subnet is not properly delegated (current: $DELEGATION)"
        log_info "Adding delegation to Microsoft.ServiceNetworking/trafficControllers..."
        az network vnet subnet update \
            --resource-group "$RESOURCE_GROUP" \
            --vnet-name "$VNET_NAME" \
            --name "$ALB_SUBNET_NAME" \
            --delegations Microsoft.ServiceNetworking/trafficControllers \
            --only-show-errors
        log_info "Delegation added ✓"
    else
        log_info "ALB subnet properly delegated ✓"
    fi
else
    log_info "Creating ALB subnet $ALB_SUBNET_NAME with delegation..."
    az network vnet subnet create \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --name "$ALB_SUBNET_NAME" \
        --address-prefixes "$ALB_SUBNET_CIDR" \
        --delegations Microsoft.ServiceNetworking/trafficControllers \
        --only-show-errors
    log_info "ALB subnet created ✓"
fi

# Get subnet IDs for reference
AKS_SUBNET_ID=$(az network vnet subnet show \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$AKS_SUBNET_NAME" \
    --query id -o tsv --only-show-errors)

ALB_SUBNET_ID=$(az network vnet subnet show \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$ALB_SUBNET_NAME" \
    --query id -o tsv --only-show-errors)

echo ""
log_info "✅ Network infrastructure created successfully!"
echo ""
log_info "📝 Network Details:"
echo "    • VNet: $VNET_NAME ($VNET_CIDR)"
echo "    • AKS Subnet: $AKS_SUBNET_NAME ($AKS_SUBNET_CIDR)"
echo "      ID: $AKS_SUBNET_ID"
echo "    • ALB Subnet: $ALB_SUBNET_NAME ($ALB_SUBNET_CIDR)"
echo "      ID: $ALB_SUBNET_ID"
echo ""
log_step "Next step:"
echo "  Run ./00-2-create-cluster.sh to create AKS cluster in this network"
echo ""
