#!/bin/bash

export SOPS_AGE_KEY_FILE=$(pwd)/key.txt
export DB_NAMESPACE="database"

if [ "$1" == "apply" ]; then
    echo "Applying postgres resources to namespace $DB_NAMESPACE..."
    /usr/local/bin/kubectl create namespace $DB_NAMESPACE
    /opt/homebrew/bin/sops --decrypt postgres/manifests/secrets.enc.yaml | /usr/local/bin/kubectl apply -n $DB_NAMESPACE -f -
    /usr/local/bin/kubectl apply -n $DB_NAMESPACE -f postgres/manifests/postgres-stset.yaml
elif [ "$1" == "delete" ]; then
    echo "Deleting postgres resources from namespace $DB_NAMESPACE..."
    /usr/local/bin/kubectl delete -n $DB_NAMESPACE -f postgres/manifests/secrets.enc.yaml
    /usr/local/bin/kubectl delete -n $DB_NAMESPACE -f postgres/manifests/postgres-stset.yaml
else
    echo "Usage: $0 [apply|delete]"
    exit 1
fi