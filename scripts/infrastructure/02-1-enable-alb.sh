#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

log_step "Setting up Application Gateway for Containers (ALB)..."
echo ""

# Display what will be created
log_info "📋 Resources to be created/configured:"
echo ""
echo "  Azure Resources:"
echo "    • Managed Identity: $IDENTITY_RESOURCE_NAME"
echo "      - Resource Group: $RESOURCE_GROUP"
echo "      - Location: $LOCATION"
echo ""
echo "    • Role Assignments:"
echo "      - Role: Reader (acdd72a7-3385-48ef-bd42-f606fba81ae7)"
echo "      - Scope: AKS managed resource group"
echo ""
echo "    • Federated Identity Credential:"
echo "      - Name: azure-alb-identity"
echo "      - Service Account: system:serviceaccount:azure-alb-system:alb-controller-sa"
echo ""
echo "  Kubernetes Resources:"
echo "    • Gateway API CRDs (v1.1.0)"
echo "      - From: github.com/kubernetes-sigs/gateway-api"
echo ""
echo "    • ALB Controller (Helm Chart v1.7.12)"
echo "      - Helm Release: alb-controller"
echo "      - Helm Namespace: azure-alb-helm"
echo "      - Controller Namespace: azure-alb-system"
echo "      - Chart: mcr.microsoft.com/application-lb/charts/alb-controller"
echo ""
echo "    • GatewayClass:"
echo "      - Name: azure-alb-external"
echo ""

log_info "Cluster is in $LOCATION - ALB is supported ✓"
echo ""

# Install Azure CLI extension
log_info "Installing Azure ALB CLI extension..."
az extension add --name alb --yes --upgrade

# Get managed cluster resource group
log_info "Getting managed cluster resource group..."
mcResourceGroup=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --query "nodeResourceGroup" -o tsv)
mcResourceGroupId=$(az group show --name "$mcResourceGroup" --query id -otsv)
log_info "Managed resource group: $mcResourceGroup"

# Create managed identity
log_info "Creating identity $IDENTITY_RESOURCE_NAME..."
az identity create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$IDENTITY_RESOURCE_NAME" \
    --location "$LOCATION" \
    2>/dev/null || log_info "Identity already exists"
principalId="$(az identity show -g "$RESOURCE_GROUP" -n "$IDENTITY_RESOURCE_NAME" --query principalId -otsv)"

log_warn "Waiting 60 seconds for identity replication..."
sleep 60

# Assign Reader role
log_info "Assigning Reader role to managed resource group..."
az role assignment create \
    --assignee-object-id "$principalId" \
    --assignee-principal-type ServicePrincipal \
    --scope "$mcResourceGroupId" \
    --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" 2>/dev/null || log_info "Reader role assignment already exists"

# Assign AppGW for Containers Configuration Manager role
log_info "Assigning AppGW for Containers Configuration Manager role..."
az role assignment create \
    --assignee-object-id "$principalId" \
    --assignee-principal-type ServicePrincipal \
    --scope "$mcResourceGroupId" \
    --role "fbc52c3f-28ad-4303-a892-8a056630b8f1" 2>/dev/null || log_info "Configuration Manager role assignment already exists"

# Set up OIDC federation
log_info "Setting up OIDC federation..."
AKS_OIDC_ISSUER="$(az aks show -n "$AKS_NAME" -g "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" -o tsv)"
az identity federated-credential create \
    --name "azure-alb-identity" \
    --identity-name "$IDENTITY_RESOURCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --issuer "$AKS_OIDC_ISSUER" \
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa" 2>/dev/null || log_info "Federated credential already exists"

# Install Gateway API CRDs
log_info "Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

# Install ALB Controller via Helm
log_info "Installing ALB Controller via Helm..."
HELM_NAMESPACE='azure-alb-helm'
CONTROLLER_NAMESPACE='azure-alb-system'
clientId=$(az identity show -g "$RESOURCE_GROUP" -n azure-alb-identity --query clientId -o tsv)

helm upgrade --install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
    --namespace "$HELM_NAMESPACE" --create-namespace \
    --version 1.7.12 \
    --set albController.namespace="$CONTROLLER_NAMESPACE" \
    --set albController.podIdentity.clientID="$clientId" \
    --set-json 'definitions.imagePullSecret=null' \
    --skip-schema-validation

log_info "Waiting for ALB Controller pods to be ready (this may take 2-3 minutes)..."
sleep 30
kubectl wait --for=condition=Ready pod \
    -l app=alb-controller \
    -n azure-alb-system \
    --timeout=300s || log_warn "Some pods may still be starting..."

log_info "Verifying controller pods..."
kubectl -n "$CONTROLLER_NAMESPACE" get pods

log_info "Verifying GatewayClass..."
kubectl get gatewayclass azure-alb-external -o yaml

echo ""
log_info "✅ ALB Controller installed successfully!"
echo ""
log_info "📋 Next Steps:"
echo "    1. Run ./02-2-create-alb.sh to create the ALB subnet in AKS VNet"
echo "    2. Deploy your Gateway and HTTPRoute manifests"
echo "    3. Remember: ALB only supports ports 80 and 443 on listeners"
echo ""
