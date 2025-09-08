#!/bin/bash

az aks create \
        --resource-group rg-aks-mooc-001 \
        --name dwk-cluster \
        --location swedencentral \
        --node-count 5 \
        --node-vm-size Standard_B2s \
        --node-osdisk-size 32 \
        --node-osdisk-type Managed \
        --os-sku Ubuntu \
        --kubernetes-version 1.32.0 \
        --tier free \
        --ssh-key-value ~/.ssh/id_rsa.pub

echo "Cluster done! Now logging in to it"

az aks get-credentials --resource-group rg-aks-mooc-001 --name dwk-cluster