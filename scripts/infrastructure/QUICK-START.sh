#!/usr/bin/env bash
# Quick reference for ALB setup - Updated for North Europe with BYO Network

# STEP 0: Create network infrastructure FIRST
./00-create-network.sh

# STEP 1: Create cluster in the pre-created network
./00-create-cluster.sh

# STEP 2: Install ALB Controller with proper RBAC
./02-1-enable-alb.sh

# STEP 3: Configure ALB subnet permissions
./02-2-create-alb.sh

# Verify everything
./verify-alb-setup.sh

# ⚠️ Save the subnet ID from the output!

# STEP 4: Deploy ALB via Kubernetes

# Create namespace
kubectl create namespace alb-infra

# Create ApplicationLoadBalancer (replace SUBNET_ID)
cat <<EOF | kubectl apply -f -
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb-demo
  namespace: alb-infra
spec:
  associations:
  - SUBNET_ID  # Replace with actual subnet ID
EOF

# Create Gateway
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-01
  namespace: default
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http
    protocol: HTTP
    port: 80
EOF

# Create HTTPRoute for your app
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
  namespace: default
spec:
  parentRefs:
  - name: gateway-01
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: my-service
      port: 8080
EOF

# Check status
kubectl get gateway gateway-01
kubectl get httproute my-app
kubectl describe gateway gateway-01

# Get ALB public IP (takes a few minutes)
kubectl get gateway gateway-01 -o jsonpath='{.status.addresses[0].value}'
