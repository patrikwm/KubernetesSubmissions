#!/bin/bash

export SOPS_AGE_KEY_FILE=$(pwd)/key.txt
export DB_NAMESPACE="exercises"

if [ "$1" == "apply" ]; then
    echo "Applying resources to namespace $DB_NAMESPACE..."
    /usr/local/bin/kubectl create namespace $DB_NAMESPACE
    /opt/homebrew/bin/sops --decrypt ping-pong_application/manifests/secret.enc.yaml | /usr/local/bin/kubectl apply -n $DB_NAMESPACE -f -
    /usr/local/bin/kubectl apply -n $DB_NAMESPACE -f ping-pong_application/manifests/deployment.yaml
    /usr/local/bin/kubectl apply -n $DB_NAMESPACE -f ping-pong_application/manifests/service.yaml
    /usr/local/bin/kubectl apply -n $DB_NAMESPACE -f ping-pong_application/manifests/ingress.yaml
elif [ "$1" == "delete" ]; then
    echo "Deleting resources from namespace $DB_NAMESPACE..."
    /opt/homebrew/bin/sops --decrypt ping-pong_application/manifests/secret.enc.yaml | /usr/local/bin/kubectl delete -n $DB_NAMESPACE -f -
    /usr/local/bin/kubectl delete -n $DB_NAMESPACE -f ping-pong_application/manifests/deployment.yaml
    /usr/local/bin/kubectl delete -n $DB_NAMESPACE -f ping-pong_application/manifests/service.yaml
    /usr/local/bin/kubectl delete -n $DB_NAMESPACE -f ping-pong_application/manifests/ingress.yaml
else
    echo "Usage: $0 [apply|delete]"
    exit 1
fi