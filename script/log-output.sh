#!/bin/bash

export SOPS_AGE_KEY_FILE=$(pwd)/key.txt
export LOG_NAMESPACE="exercises"

if [ "$1" == "apply" ]; then
    echo "Applying log-output resources to namespace $LOG_NAMESPACE..."
    /usr/local/bin/kubectl create namespace $LOG_NAMESPACE
    /usr/local/bin/kubectl apply -n $LOG_NAMESPACE -f log_output/manifests/configmap.yaml
    /usr/local/bin/kubectl apply -n $LOG_NAMESPACE -f log_output/manifests/deployment.yaml
    /usr/local/bin/kubectl apply -n $LOG_NAMESPACE -f log_output/manifests/service.yaml
    /usr/local/bin/kubectl apply -n $LOG_NAMESPACE -f log_output/manifests/ingress.yaml
elif [ "$1" == "delete" ]; then
    echo "Deleting log-output resources from namespace $LOG_NAMESPACE..."
    /usr/local/bin/kubectl delete -n $LOG_NAMESPACE -f log_output/manifests/ingress.yaml
    /usr/local/bin/kubectl delete -n $LOG_NAMESPACE -f log_output/manifests/service.yaml
    /usr/local/bin/kubectl delete -n $LOG_NAMESPACE -f log_output/manifests/deployment.yaml
    /usr/local/bin/kubectl delete -n $LOG_NAMESPACE -f log_output/manifests/configmap.yaml
else
    echo "Usage: $0 [apply|delete]"
    exit 1
fi