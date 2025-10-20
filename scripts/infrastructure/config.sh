#!/usr/bin/env bash
# Shared configuration for all infrastructure scripts

export RESOURCE_GROUP="rg-aks-mooc-001"
export AKS_NAME="dwk-cluster"
export LOCATION="northeurope"
export SUBSCRIPTION_ID='56d9a591-8bfe-40fb-96a4-17b3ec30d23a'
export IDENTITY_RESOURCE_NAME='azure-alb-identity'

# Network configuration
export VNET_NAME="vnet-${AKS_NAME}"
export VNET_CIDR="10.224.0.0/15"        # Spans 10.224.0.0/16 and 10.225.0.0/16
export AKS_SUBNET_NAME="aks-subnet"
export AKS_SUBNET_CIDR="10.224.0.0/24"  # Nodes & pods (Azure CNI)
export ALB_SUBNET_NAME="alb-subnet"
export ALB_SUBNET_CIDR="10.225.0.0/24"  # Must be /24 and delegated

# AKS service networking (separate from VNet to avoid overlap)
export SERVICE_CIDR="10.226.0.0/16"     # Kubernetes services (ClusterIP, etc.)
export DNS_SERVICE_IP="10.226.0.10"     # Must be within SERVICE_CIDR
export DOCKER_BRIDGE_CIDR="172.17.0.1/16" # Docker bridge network

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}
