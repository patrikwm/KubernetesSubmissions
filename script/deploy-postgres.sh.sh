#!/bin/bash

export SOPS_AGE_KEY_FILE=$(pwd)/key.txt
/opt/homebrew/bin/sops --decrypt postgres/manifests/secrets.enc.yaml | /usr/local/bin/kubectl apply -f -
/usr/local/bin/kubectl apply -f postgres/manifests/postgres-stset.yaml