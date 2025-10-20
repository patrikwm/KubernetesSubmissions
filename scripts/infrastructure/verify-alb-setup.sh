#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "========================================"
echo "  ALB Setup Verification"
echo "========================================"
echo ""

# Check 1: Cluster region
echo "✓ Checking cluster region..."
CLUSTER_LOCATION=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query location -o tsv 2>/dev/null || echo "NOT_FOUND")

if [ "$CLUSTER_LOCATION" = "NOT_FOUND" ]; then
    log_error "Cluster not found!"
    echo "  Run: ./00-create-cluster.sh"
    exit 1
elif [ "$CLUSTER_LOCATION" != "northeurope" ] && [ "$CLUSTER_LOCATION" != "westeurope" ]; then
    log_error "Cluster is in $CLUSTER_LOCATION - ALB not supported!"
    echo "  ALB requires northeurope or westeurope"
    echo "  Recreate cluster in supported region"
    exit 1
else
    log_info "Cluster region: $CLUSTER_LOCATION ✓"
fi
echo ""

# Check 2: OIDC and Workload Identity
echo "✓ Checking OIDC and Workload Identity..."
OIDC_ENABLED=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query oidcIssuerProfile.enabled -o tsv)
WI_ENABLED=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query securityProfile.workloadIdentity.enabled -o tsv)

if [ "$OIDC_ENABLED" != "true" ]; then
    log_error "OIDC not enabled!"
    exit 1
fi

if [ "$WI_ENABLED" != "true" ]; then
    log_error "Workload Identity not enabled!"
    exit 1
fi

log_info "OIDC enabled ✓"
log_info "Workload Identity enabled ✓"
echo ""

# Check 3: Managed Identity
echo "✓ Checking managed identity..."
IDENTITY_EXISTS=$(az identity show -g "$RESOURCE_GROUP" -n "$IDENTITY_RESOURCE_NAME" --query id -o tsv 2>/dev/null || echo "NOT_FOUND")

if [ "$IDENTITY_EXISTS" = "NOT_FOUND" ]; then
    log_error "Managed identity not found!"
    echo "  Run: ./02-1-enable-alb.sh"
    exit 1
else
    log_info "Managed identity exists ✓"
fi
echo ""

# Check 4: Role Assignments
echo "✓ Checking RBAC role assignments..."
principalId=$(az identity show -g "$RESOURCE_GROUP" -n "$IDENTITY_RESOURCE_NAME" --query principalId -o tsv)
ROLE_COUNT=$(az role assignment list --assignee "$principalId" --query "length(@)" -o tsv)

if [ "$ROLE_COUNT" -lt 3 ]; then
    log_warn "Only $ROLE_COUNT role(s) assigned - expected 3!"
    echo "  Required roles:"
    echo "    - Reader"
    echo "    - AppGW for Containers Configuration Manager"
    echo "    - Network Contributor (on ALB subnet)"
    echo "  Run: ./02-1-enable-alb.sh and ./02-2-create-alb.sh"
else
    log_info "RBAC roles assigned: $ROLE_COUNT ✓"
    az role assignment list --assignee "$principalId" --query "[].{Role:roleDefinitionName, Scope:scope}" -o table
fi
echo ""

# Check 5: ALB Controller
echo "✓ Checking ALB Controller..."
if ! kubectl get namespace azure-alb-system &>/dev/null; then
    log_error "ALB Controller namespace not found!"
    echo "  Run: ./02-1-enable-alb.sh"
    exit 1
fi

POD_STATUS=$(kubectl get pods -n azure-alb-system -l app=alb-controller --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$POD_STATUS" -eq 0 ]; then
    log_error "ALB Controller pods not found!"
    echo "  Run: ./02-1-enable-alb.sh"
    exit 1
fi

READY_PODS=$(kubectl get pods -n azure-alb-system -l app=alb-controller --no-headers 2>/dev/null | grep "Running" | wc -l || echo "0")
if [ "$READY_PODS" -eq 0 ]; then
    log_warn "ALB Controller pods not ready!"
    kubectl get pods -n azure-alb-system -l app=alb-controller
else
    log_info "ALB Controller pods running: $READY_PODS ✓"
fi
echo ""

# Check 6: GatewayClass
echo "✓ Checking GatewayClass..."
if ! kubectl get gatewayclass azure-alb-external &>/dev/null; then
    log_error "GatewayClass 'azure-alb-external' not found!"
    echo "  Run: ./02-1-enable-alb.sh"
    exit 1
else
    log_info "GatewayClass exists ✓"
fi
echo ""

# Check 7: ALB Subnet
echo "✓ Checking ALB subnet..."
MC_RG=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query nodeResourceGroup -o tsv)
CLUSTER_SUBNET_ID=$(az vmss list -g "$MC_RG" --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv 2>/dev/null || echo "NOT_FOUND")

if [ "$CLUSTER_SUBNET_ID" = "NOT_FOUND" ]; then
    log_error "Could not find cluster subnet!"
    exit 1
fi

VNET_ID=${CLUSTER_SUBNET_ID%/subnets/*}
VNET_RG=$(echo "$VNET_ID" | cut -d'/' -f5)
VNET_NAME=$(echo "$VNET_ID" | cut -d'/' -f9)

ALB_SUBNET_EXISTS=$(az network vnet subnet show -g "$VNET_RG" --vnet-name "$VNET_NAME" -n "alb-subnet" --query id -o tsv 2>/dev/null || echo "NOT_FOUND")

if [ "$ALB_SUBNET_EXISTS" = "NOT_FOUND" ]; then
    log_warn "ALB subnet not found in VNet!"
    echo "  Run: ./02-2-create-alb.sh"
else
    log_info "ALB subnet exists in AKS VNet ✓"

    # Check delegation
    DELEGATION=$(az network vnet subnet show -g "$VNET_RG" --vnet-name "$VNET_NAME" -n "alb-subnet" --query "delegations[0].serviceName" -o tsv)
    if [ "$DELEGATION" = "Microsoft.ServiceNetworking/trafficControllers" ]; then
        log_info "Subnet properly delegated ✓"
    else
        log_warn "Subnet delegation incorrect: $DELEGATION"
    fi
fi
echo ""

# Check 8: Helm release
echo "✓ Checking Helm release..."
if helm list -n azure-alb-helm 2>/dev/null | grep -q "alb-controller"; then
    HELM_VERSION=$(helm list -n azure-alb-helm -o json 2>/dev/null | grep -o '"app_version":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    log_info "Helm release installed (version: $HELM_VERSION) ✓"
else
    log_warn "Helm release not found"
    echo "  Expected in namespace: azure-alb-helm"
fi
echo ""

# Summary
echo "========================================"
echo "  Summary"
echo "========================================"
echo ""

if [ "$CLUSTER_LOCATION" = "northeurope" ] || [ "$CLUSTER_LOCATION" = "westeurope" ]; then
    if [ "$OIDC_ENABLED" = "true" ] && [ "$WI_ENABLED" = "true" ]; then
        if [ "$IDENTITY_EXISTS" != "NOT_FOUND" ]; then
            if [ "$READY_PODS" -gt 0 ]; then
                if [ "$ALB_SUBNET_EXISTS" != "NOT_FOUND" ]; then
                    log_info "✅ All checks passed! ALB is ready to use."
                    echo ""
                    echo "Next steps:"
                    echo "  1. Create ApplicationLoadBalancer CR"
                    echo "  2. Create Gateway"
                    echo "  3. Create HTTPRoute"
                    echo ""
                    echo "See QUICK-START.sh for examples"
                else
                    log_warn "⚠️ Almost ready - create ALB subnet:"
                    echo "  Run: ./02-2-create-alb.sh"
                fi
            else
                log_warn "⚠️ ALB Controller not ready - check logs:"
                echo "  kubectl logs -n azure-alb-system -l app=alb-controller"
            fi
        else
            log_error "❌ Setup incomplete - run:"
            echo "  ./02-1-enable-alb.sh"
            echo "  ./02-2-create-alb.sh"
        fi
    else
        log_error "❌ Cluster missing required features - recreate with:"
        echo "  ./00-create-cluster.sh"
    fi
else
    log_error "❌ Cluster in wrong region - ALB not available"
    echo "  Recreate cluster in northeurope or westeurope"
fi
echo ""
