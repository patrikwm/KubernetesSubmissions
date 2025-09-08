#!/bin/bash

RESOURCE_GROUP="rg-aks-mooc-001"
CLUSTER_NAME="dwk-cluster"
LOCATION="swedencentral"

if [ "$1" == "create" ]; then
    echo "Creating AKS cluster $CLUSTER_NAME in resource group $RESOURCE_GROUP..."
    az aks create \
            --resource-group $RESOURCE_GROUP \
            --name $CLUSTER_NAME \
            --location $LOCATION \
            --node-count 5 \
            --node-vm-size Standard_B2s \
            --node-osdisk-size 32 \
            --node-osdisk-type Managed \
            --os-sku Ubuntu \
            --kubernetes-version 1.32.0 \
            --tier free \
            --ssh-key-value ~/.ssh/id_rsa.pub

    echo "Install Nginx Routing"
    az aks approuting enable --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

    echo "Cluster done! Now logging in to it"
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

elif [ "$1" == "delete" ]; then
    echo "Deleting AKS cluster $CLUSTER_NAME from resource group $RESOURCE_GROUP..."
    az aks delete \
            --resource-group $RESOURCE_GROUP \
            --name $CLUSTER_NAME \
            --yes \
            --no-wait
    echo "AKS cluster deletion initiated (running in background)"
else
    echo "Usage: $0 [create|delete]"
    echo ""
    echo "Examples:"
    echo "  $0 create  # Create the AKS cluster with nginx routing"
    echo "  $0 delete  # Delete the AKS cluster"
    exit 1
fi