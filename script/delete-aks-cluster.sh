#!/bin/bash

az aks delete \
        --resource-group rg-aks-mooc-001 \
        --name dwk-cluster \
        --yes \
        --no-wait