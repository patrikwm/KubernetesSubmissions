#!/bin/bash

export RESOURCE_GROUP="rg-aks-mooc-001"
export AKS_NAME="dwk-cluster"
export LOCATION="swedencentral"
export SUBSCRIPTION_ID='56d9a591-8bfe-40fb-96a4-17b3ec30d23a'
export IDENTITY_RESOURCE_NAME='azure-alb-identity'

if [ "$1" == "create" ]; then
    echo "Creating AKS cluster $AKS_NAME in resource group $RESOURCE_GROUP..."

    az login
    az account set --subscription $SUBSCRIPTION_ID

    # Register required resource providers on Azure.
    az provider register --namespace Microsoft.ContainerService
    az provider register --namespace Microsoft.Network
    az provider register --namespace Microsoft.NetworkFunction
    az provider register --namespace Microsoft.ServiceNetworking

    # Install Azure CLI extensions.
    az extension add --name alb
    az aks create \
            --resource-group $RESOURCE_GROUP \
            --name $AKS_NAME \
            --location $LOCATION \
            --node-count 5 \
            --node-vm-size Standard_B2s \
            --node-osdisk-size 32 \
            --node-osdisk-type Managed \
            --os-sku Ubuntu \
            --kubernetes-version 1.32.0 \
            --tier free \
            --ssh-key-value ~/.ssh/id_rsa.pub \
            --network-plugin azure \
            --enable-oidc-issuer \
            --enable-workload-identity

    echo "Cluster created successfully! Now logging in to it..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

    # Create managed identity for ALB controller and set up federation
    mcResourceGroup=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "nodeResourceGroup" -o tsv)
    mcResourceGroupId=$(az group show --name $mcResourceGroup --query id -otsv)

    echo "Creating identity $IDENTITY_RESOURCE_NAME in resource group $RESOURCE_GROUP"
    az identity create --resource-group $RESOURCE_GROUP --name $IDENTITY_RESOURCE_NAME
    principalId="$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -otsv)"

    echo "Waiting 60 seconds to allow for replication of the identity..."
    sleep 60

    echo "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"
    az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $mcResourceGroupId --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

    echo "Set up federation with AKS OIDC issuer"
    AKS_OIDC_ISSUER="$(az aks show -n "$AKS_NAME" -g "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" -o tsv)"
    az identity federated-credential create --name "azure-alb-identity" \
        --identity-name "$IDENTITY_RESOURCE_NAME" \
        --resource-group $RESOURCE_GROUP \
        --issuer "$AKS_OIDC_ISSUER" \
        --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

    # Install ALB Controller using Helm
    echo "Installing Gateway API CRDs first..."
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

    echo "Installing ALB Controller..."
    HELM_NAMESPACE='default'
    CONTROLLER_NAMESPACE='azure-alb-system'

    helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
         --namespace $HELM_NAMESPACE \
         --version 1.7.9 \
         --set albController.namespace=$CONTROLLER_NAMESPACE \
         --set albController.podIdentity.clientID=$(az identity show -g $RESOURCE_GROUP -n azure-alb-identity --query clientId -o tsv)    # Verify ALB Controller installation
    echo "Verifying ALB Controller installation..."
    echo "Waiting for ALB Controller pods to be ready..."
    kubectl wait --for=condition=Ready pod -l app=alb-controller -n azure-alb-system --timeout=300s

    echo "Checking ALB Controller pods:"
    kubectl get pods -n azure-alb-system

    echo "Verifying GatewayClass azure-alb-external:"
    kubectl get gatewayclass azure-alb-external -o yaml

elif [ "$1" == "delete" ]; then
    echo "Deleting all resources for AKS cluster $AKS_NAME from resource group $RESOURCE_GROUP..."

    # Login and set subscription
    az login
    az account set --subscription $SUBSCRIPTION_ID

    # Get credentials to access the cluster for cleanup
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME 2>/dev/null || echo "Could not get cluster credentials"

    # Uninstall ALB Controller if it exists
    echo "Uninstalling ALB Controller..."
    helm uninstall alb-controller 2>/dev/null || echo "ALB Controller not found or already uninstalled"
    kubectl delete ns azure-alb-system 2>/dev/null || echo "azure-alb-system namespace not found"
    kubectl delete gatewayclass azure-alb-external 2>/dev/null || echo "GatewayClass azure-alb-external not found"

    # Delete federated credential first
    echo "Deleting federated credential for identity $IDENTITY_RESOURCE_NAME..."
    az identity federated-credential delete \
        --name "azure-alb-identity" \
        --identity-name "$IDENTITY_RESOURCE_NAME" \
        --resource-group $RESOURCE_GROUP \
        --yes || echo "Federated credential not found or already deleted"

    # Get managed cluster resource group before deleting the cluster
    mcResourceGroup=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "nodeResourceGroup" -o tsv 2>/dev/null || echo "")
    mcResourceGroupId=$(az group show --name $mcResourceGroup --query id -otsv 2>/dev/null || echo "")
    principalId=$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -otsv 2>/dev/null || echo "")

    # Remove role assignment if it exists
    if [ ! -z "$principalId" ] && [ ! -z "$mcResourceGroupId" ]; then
        echo "Removing Reader role assignment for identity..."
        az role assignment delete \
            --assignee-object-id $principalId \
            --scope $mcResourceGroupId \
            --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" || echo "Role assignment not found or already deleted"
    fi

    # Delete the managed identity
    echo "Deleting managed identity $IDENTITY_RESOURCE_NAME..."
    az identity delete \
        --resource-group $RESOURCE_GROUP \
        --name $IDENTITY_RESOURCE_NAME || echo "Identity not found or already deleted"

    # Delete the AKS cluster
    echo "Deleting AKS cluster $AKS_NAME..."
    az aks delete \
            --resource-group $RESOURCE_GROUP \
            --name $AKS_NAME \
            --yes \
            --no-wait

    echo "All resources deletion initiated (AKS cluster running in background)"
    echo "Note: The managed cluster resource group will be automatically deleted by Azure when the cluster deletion completes"
else
    echo "Usage: $0 [create|delete]"
    echo ""
    echo "Examples:"
    echo "  $0 create  # Create the AKS cluster with Application Gateway for Containers ALB Controller"
    echo "  $0 delete  # Delete the AKS cluster and all related resources"
    exit 1
fi