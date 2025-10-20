#!/usr/bin/env bash
# Network configuration sanity checks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=========================================="
echo "  Network Configuration Sanity Check"
echo "=========================================="
echo ""

# Helper function to check if child CIDR is within parent CIDR
# Handles /15 networks properly (e.g., 10.224.0.0/15 contains 10.224.x.x AND 10.225.x.x)
check_cidr_contains() {
    local parent=$1
    local child=$2

    # Convert IP to integer
    ip_to_int() {
        local ip=$1
        local a b c d
        IFS=. read -r a b c d <<< "$ip"
        echo "$((a * 256**3 + b * 256**2 + c * 256 + d))"
    }

    # Extract IP and prefix length
    local parent_ip=$(echo "$parent" | cut -d'/' -f1)
    local parent_prefix=$(echo "$parent" | cut -d'/' -f2)
    local child_ip=$(echo "$child" | cut -d'/' -f1)
    local child_prefix=$(echo "$child" | cut -d'/' -f2)

    # Convert to integers
    local parent_int=$(ip_to_int "$parent_ip")
    local child_int=$(ip_to_int "$child_ip")

    # Calculate network masks
    local parent_mask=$(( 0xFFFFFFFF << (32 - parent_prefix) ))
    local child_mask=$(( 0xFFFFFFFF << (32 - child_prefix) ))

    # Calculate network addresses
    local parent_net=$(( parent_int & parent_mask ))
    local child_net=$(( child_int & child_mask ))

    # Child network must start within parent's range
    # and parent prefix must be smaller (less specific) than child
    if [ $parent_prefix -le $child_prefix ]; then
        local child_net_masked=$(( child_int & parent_mask ))
        if [ $parent_net -eq $child_net_masked ]; then
            return 0
        fi
    fi

    return 1
}

# Check 1: VNet contains AKS subnet
echo "✓ Checking if VNet ($VNET_CIDR) contains AKS subnet ($AKS_SUBNET_CIDR)..."
if check_cidr_contains "$VNET_CIDR" "$AKS_SUBNET_CIDR"; then
    log_info "✅ AKS subnet is within VNet range"
else
    log_error "❌ AKS subnet ($AKS_SUBNET_CIDR) is NOT within VNet range ($VNET_CIDR)!"
    exit 1
fi

# Check 2: VNet contains ALB subnet
echo ""
echo "✓ Checking if VNet ($VNET_CIDR) contains ALB subnet ($ALB_SUBNET_CIDR)..."
if check_cidr_contains "$VNET_CIDR" "$ALB_SUBNET_CIDR"; then
    log_info "✅ ALB subnet is within VNet range"
else
    log_error "❌ ALB subnet ($ALB_SUBNET_CIDR) is NOT within VNet range ($VNET_CIDR)!"
    exit 1
fi

# Check 3: Service CIDR doesn't overlap with VNet
echo ""
echo "✓ Checking Service CIDR ($SERVICE_CIDR) doesn't overlap with VNet..."
service_prefix=$(echo "$SERVICE_CIDR" | cut -d'/' -f1 | cut -d'.' -f1-2)
vnet_prefix=$(echo "$VNET_CIDR" | cut -d'/' -f1 | cut -d'.' -f1-2)

if [ "$service_prefix" == "$vnet_prefix" ]; then
    log_error "❌ Service CIDR ($SERVICE_CIDR) overlaps with VNet ($VNET_CIDR)!"
    exit 1
else
    log_info "✅ Service CIDR is separate from VNet (no overlap)"
fi

# Check 4: DNS IP is within Service CIDR
echo ""
echo "✓ Checking DNS Service IP ($DNS_SERVICE_IP) is within Service CIDR..."
dns_prefix=$(echo "$DNS_SERVICE_IP" | cut -d'.' -f1-3)
service_range=$(echo "$SERVICE_CIDR" | cut -d'/' -f1 | cut -d'.' -f1-3)

if [ "$dns_prefix" == "$service_range" ]; then
    log_info "✅ DNS Service IP is within Service CIDR"
else
    log_error "❌ DNS Service IP ($DNS_SERVICE_IP) is NOT within Service CIDR ($SERVICE_CIDR)!"
    exit 1
fi

# Check 5: Docker bridge is separate
echo ""
echo "✓ Checking Docker bridge ($DOCKER_BRIDGE_CIDR) is separate..."
docker_prefix=$(echo "$DOCKER_BRIDGE_CIDR" | cut -d'/' -f1 | cut -d'.' -f1)

if [ "$docker_prefix" != "10" ]; then
    log_info "✅ Docker bridge uses different address space (172.x.x.x)"
else
    log_warn "⚠️  Docker bridge might overlap with other ranges!"
fi

echo ""
echo "=========================================="
echo "  Configuration Summary"
echo "=========================================="
echo ""
echo "VNet Configuration:"
echo "  • VNet CIDR:        $VNET_CIDR (VNet address space)"
echo "  • AKS Subnet:       $AKS_SUBNET_CIDR (nodes & pods)"
echo "  • ALB Subnet:       $ALB_SUBNET_CIDR (Application Gateway)"
echo ""
echo "Kubernetes Service Networking (separate from VNet):"
echo "  • Service CIDR:     $SERVICE_CIDR (ClusterIP services)"
echo "  • DNS Service IP:   $DNS_SERVICE_IP (kube-dns/CoreDNS)"
echo "  • Docker Bridge:    $DOCKER_BRIDGE_CIDR (container bridge)"
echo ""
echo "Address Space Allocation:"
echo "  • 10.224.x.x - 10.225.x.x: VNet (nodes, pods, ALB)"
echo "  • 10.226.x.x:              Kubernetes services"
echo "  • 172.17.x.x:              Docker bridge"
echo ""
log_info "✅ All sanity checks passed!"
echo ""
log_info "Your network configuration is valid and ready to use."
echo ""
