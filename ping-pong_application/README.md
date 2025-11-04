# Chapter 4

## Exercise: 3.3. To the Gateway

- To use gateway with AKS you need to use Azure Application Gateway for Containers (ALB).
- ALB is more complex to set up but has more features and better integration with Azure.
- [Application gateway for containers](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/quickstart-deploy-application-gateway-for-containers-alb-controller?tabs=install-helm-windows)
- It requires the cluster and ALB to be in a supprted region.
- It requires specific network setup.
- The ALB controller needs to be installed in the cluster.
- The Managed Identity needs to be created and assigned permissions.
- The Kubernetes Cluster needs to have OIDC issuer enabled.


Since im deleting the cluster at the end of each day i will create a script to automate the process.


## Create network

```bash
➜ ./scripts/infrastructure/00-0-check-network-config.sh
==========================================
  Network Configuration Sanity Check
==========================================

✓ Checking if VNet (10.224.0.0/15) contains AKS subnet (10.224.0.0/24)...
[INFO] ✅ AKS subnet is within VNet range

✓ Checking if VNet (10.224.0.0/15) contains ALB subnet (10.225.0.0/24)...
[INFO] ✅ ALB subnet is within VNet range

✓ Checking Service CIDR (10.226.0.0/16) doesn't overlap with VNet...
[INFO] ✅ Service CIDR is separate from VNet (no overlap)

✓ Checking DNS Service IP (10.226.0.10) is within Service CIDR...
[INFO] ✅ DNS Service IP is within Service CIDR

✓ Checking Docker bridge (172.17.0.1/16) is separate...
[INFO] ✅ Docker bridge uses different address space (172.x.x.x)

==========================================
  Configuration Summary
==========================================

VNet Configuration:
  • VNet CIDR:        10.224.0.0/15 (VNet address space)
  • AKS Subnet:       10.224.0.0/24 (nodes & pods)
  • ALB Subnet:       10.225.0.0/24 (Application Gateway)

Kubernetes Service Networking (separate from VNet):
  • Service CIDR:     10.226.0.0/16 (ClusterIP services)
  • DNS Service IP:   10.226.0.10 (kube-dns/CoreDNS)
  • Docker Bridge:    172.17.0.1/16 (container bridge)

Address Space Allocation:
  • 10.224.x.x - 10.225.x.x: VNet (nodes, pods, ALB)
  • 10.226.x.x:              Kubernetes services
  • 172.17.x.x:              Docker bridge

[INFO] ✅ All sanity checks passed!

[INFO] Your network configuration is valid and ready to use.

➜ ./scripts/infrastructure/00-1-create-network.sh
[STEP] Creating network infrastructure for AKS and ALB...

[INFO] 📋 Network resources to be created:

  Virtual Network:
    • Name: vnet-dwk-cluster
    • Resource Group: rg-aks-mooc-001
    • Location: northeurope
    • Address Space: 10.224.0.0/15 (/15 = 131,072 IPs)

  AKS Subnet:
    • Name: aks-subnet
    • Address Prefix: 10.224.0.0/24 (/24 = 256 IPs)
    • Purpose: AKS nodes and pods (Azure CNI)

  ALB Subnet:
    • Name: alb-subnet
    • Address Prefix: 10.225.0.0/24 (/24 = 256 IPs)
    • Delegation: Microsoft.ServiceNetworking/trafficControllers
    • Purpose: Application Gateway for Containers

[INFO] Network Topology:

    vnet-dwk-cluster (10.224.0.0/15)
    ├── aks-subnet (10.224.0.0/24) ← AKS nodes & pods
    └── alb-subnet (10.225.0.0/24) ← Application Gateway

[INFO] Ensuring resource group exists...
[INFO] Resource group already exists
[INFO] VNet vnet-dwk-cluster already exists
[INFO] VNet already has correct address space ✓
[INFO] AKS subnet aks-subnet already exists
[INFO] ALB subnet alb-subnet already exists
[INFO] ALB subnet properly delegated ✓

[INFO] ✅ Network infrastructure created successfully!

[INFO] 📝 Network Details:
    • VNet: vnet-dwk-cluster (10.224.0.0/15)
    • AKS Subnet: aks-subnet (10.224.0.0/24)
      ID: /subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/aks-subnet
    • ALB Subnet: alb-subnet (10.225.0.0/24)
      ID: /subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/alb-subnet

[STEP] Next step:
  Run ./00-2-create-cluster.sh to create AKS cluster in this network
```

ALB Subnet ID is required in the `manifests/infra/alb-gateway.yml` file when deploying the ALB gateway.

## Create cluster

```bash
➜ scripts/infrastructure/00-2-create-cluster.sh
[STEP] Creating AKS cluster dwk-cluster in resource group rg-aks-mooc-001...

[INFO] Verifying network infrastructure...
[INFO] Using existing network:
[INFO]   • VNet: vnet-dwk-cluster (10.224.0.0/15)
[INFO]   • AKS Subnet: aks-subnet (10.224.0.0/24)
[INFO]   • Service CIDR: 10.226.0.0/16 (for Kubernetes services)
[INFO]   • DNS Service IP: 10.226.0.10
[INFO]   • Subnet ID: /subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/aks-subnet

[INFO] Checking Azure login status...
[INFO] Registering Azure resource providers...
[INFO] Ensuring resource group exists...
[INFO] Creating AKS cluster (this takes ~5-10 minutes)...
[INFO] Using location: northeurope (required for ALB support)
# OUTPUT OMMITTED FOR BREVITY
[INFO] Getting cluster credentials...
Merged "dwk-cluster" as current context in /Users/patrik/.kube/config
[INFO] Verifying cluster...
Kubernetes control plane is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-7sb2iycn.hcp.northeurope.azmk8s.io:443
CoreDNS is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-7sb2iycn.hcp.northeurope.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-7sb2iycn.hcp.northeurope.azmk8s.io:443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
NAME                                STATUS   ROLES    AGE    VERSION
aks-nodepool1-23125959-vmss000000   Ready    <none>   2m1s   v1.32.7
aks-nodepool1-23125959-vmss000001   Ready    <none>   2m     v1.32.7
aks-nodepool1-23125959-vmss000002   Ready    <none>   2m4s   v1.32.7

[INFO] ✅ Cluster created successfully!

[STEP] Next steps:
  1. Run ./02-1-enable-alb.sh to install ALB Controller
  2. Then deploy your applications using Gateway and HTTPRoute
```

## Check that nodes are available

```bash
➜ k get nodes
NAME                                STATUS   ROLES    AGE     VERSION
aks-nodepool1-23125959-vmss000000   Ready    <none>   2m46s   v1.32.7
aks-nodepool1-23125959-vmss000001   Ready    <none>   2m45s   v1.32.7
aks-nodepool1-23125959-vmss000002   Ready    <none>   2m49s   v1.32.7
```

## Verify pods are up and running

```bash
➜ k get pods -A -o wide
NAMESPACE     NAME                                                  READY   STATUS    RESTARTS        AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
kube-system   azure-cns-44865                                       1/1     Running   0               3m15s   10.224.0.10   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   azure-cns-jpsq2                                       1/1     Running   0               3m18s   10.224.0.39   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   azure-cns-xtb6w                                       1/1     Running   0               3m14s   10.224.0.65   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   azure-ip-masq-agent-7bm6h                             1/1     Running   0               3m15s   10.224.0.10   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   azure-ip-masq-agent-m5mmd                             1/1     Running   0               3m13s   10.224.0.65   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   azure-ip-masq-agent-w878c                             1/1     Running   0               3m18s   10.224.0.39   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   azure-wi-webhook-controller-manager-8f5b87df4-n4j8q   1/1     Running   0               117s    10.224.0.11   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   azure-wi-webhook-controller-manager-8f5b87df4-q6nbp   1/1     Running   0               117s    10.224.0.67   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   cilium-5j4fz                                          1/1     Running   0               3m13s   10.224.0.65   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   cilium-chgjk                                          1/1     Running   0               3m15s   10.224.0.10   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   cilium-operator-7d5fd7669c-cn5nz                      1/1     Running   0               3m47s   10.224.0.10   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   cilium-operator-7d5fd7669c-fnh72                      1/1     Running   0               3m46s   10.224.0.65   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   cilium-pq7sr                                          1/1     Running   0               3m18s   10.224.0.39   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   cloud-node-manager-5ftz9                              1/1     Running   0               3m18s   10.224.0.39   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   cloud-node-manager-shxhr                              1/1     Running   0               3m13s   10.224.0.65   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   cloud-node-manager-vz4zw                              1/1     Running   0               3m15s   10.224.0.10   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   coredns-7945956757-cgrg2                              1/1     Running   0               2m25s   10.224.0.84   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   coredns-7945956757-lqtvk                              1/1     Running   0               3m37s   10.224.0.41   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   coredns-autoscaler-65cc77f87-pdtnf                    1/1     Running   0               3m37s   10.224.0.57   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   csi-azuredisk-node-5g5tn                              3/3     Running   0               3m17s   10.224.0.39   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   csi-azuredisk-node-jgkjc                              3/3     Running   1 (2m34s ago)   3m15s   10.224.0.10   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   csi-azuredisk-node-wtzw8                              3/3     Running   0               3m14s   10.224.0.65   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   csi-azurefile-node-5t9m2                               3/3     Running   0               3m13s   10.224.0.65   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   csi-azurefile-node-dd7tv                               3/3     Running   1 (2m34s ago)   3m15s   10.224.0.10   aks-nodepool1-23125959-vmss000000   <none>           <none>
kube-system   csi-azurefile-node-fj6v4                               3/3     Running   0               3m17s   10.224.0.39   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   konnectivity-agent-5c88846f5f-5n7t8                   1/1     Running   0               3m36s   10.224.0.49   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   konnectivity-agent-5c88846f5f-nzxnk                   1/1     Running   0               2m25s   10.224.0.83   aks-nodepool1-23125959-vmss000001   <none>           <none>
kube-system   konnectivity-agent-autoscaler-6c64c6dfc9-nl8gp        1/1     Running   0               3m36s   10.224.0.4    aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   metrics-server-64d8f85775-9d4tm                       2/2     Running   0               3m36s   10.224.0.53   aks-nodepool1-23125959-vmss000002   <none>           <none>
kube-system   metrics-server-64d8f85775-9pvjv                       2/2     Running   0               3m35s   10.224.0.42   aks-nodepool1-23125959-vmss000002   <none>           <none>
```

## Check gatewayclasses

```bash
➜ k get gatewayclass
error: the server doesn't have a resource type "gatewayclass"
➜ k get gateway
error: the server doesn't have a resource type "gateway"
```

## Deploy ALB controller

```bash
➜ ./scripts/infrastructure/02-1-enable-alb.sh
[STEP] Setting up Application Gateway for Containers (ALB)...

[INFO] 📋 Resources to be created/configured:

  Azure Resources:
    • Managed Identity: azure-alb-identity
      - Resource Group: rg-aks-mooc-001
      - Location: northeurope

    • Role Assignments:
      - Role: Reader (acdd72a7-3385-48ef-bd42-f606fba81ae7)
      - Scope: AKS managed resource group

    • Federated Identity Credential:
      - Name: azure-alb-identity
      - Service Account: system:serviceaccount:azure-alb-system:alb-controller-sa

  Kubernetes Resources:
    • Gateway API CRDs (v1.1.0)
      - From: github.com/kubernetes-sigs/gateway-api

    • ALB Controller (Helm Chart v1.7.12)
      - Helm Release: alb-controller
      - Helm Namespace: azure-alb-helm
      - Controller Namespace: azure-alb-system
      - Chart: mcr.microsoft.com/application-lb/charts/alb-controller

    • GatewayClass:
      - Name: azure-alb-external

[INFO] Cluster is in northeurope - ALB is supported ✓

[INFO] Installing Azure ALB CLI extension...
No stable version of 'alb' to install. Preview versions allowed.
Extension 'alb' 2.0.1 is already installed.
Latest version of 'alb' is already installed.
[INFO] Getting managed cluster resource group...
[INFO] Managed resource group: MC_rg-aks-mooc-001_dwk-cluster_northeurope
[INFO] Creating identity azure-alb-identity...
[WARN] Waiting 60 seconds for identity replication...
[INFO] Assigning Reader role to managed resource group...
[INFO] Assigning AppGW for Containers Configuration Manager role...
[INFO] Setting up OIDC federation...
[INFO] Installing Gateway API CRDs...
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io created
[INFO] Installing ALB Controller via Helm...
Release "alb-controller" does not exist. Installing it now.
Pulled: mcr.microsoft.com/application-lb/charts/alb-controller:1.7.12
Digest: sha256:1026cf47fde5d09540ad0471db6f86235884517e743319b37b4e282744cf2b5c
NAME: alb-controller
LAST DEPLOYED: Tue Nov  4 08:20:17 2025
NAMESPACE: azure-alb-helm
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Congratulations! The ALB Controller has been installed in your Kubernetes cluster!
[INFO] Waiting for ALB Controller pods to be ready (this may take 2-3 minutes)...
pod/alb-controller-9c66f55b5-f7ns7 condition met
pod/alb-controller-9c66f55b5-vk7wq condition met
[INFO] Verifying controller pods...
NAME                             READY   STATUS    RESTARTS   AGE
alb-controller-9c66f55b5-f7ns7   1/1     Running   0          30s
alb-controller-9c66f55b5-vk7wq   1/1     Running   0          30s
[INFO] Verifying GatewayClass...
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  creationTimestamp: "2025-11-04T07:20:28Z"
  generation: 1
  name: azure-alb-external
  resourceVersion: "3962"
  uid: be902e5c-366a-441d-9a2b-5c34de431b3b
spec:
  controllerName: alb.networking.azure.io/alb-controller
status:
  conditions:
  - lastTransitionTime: "2025-11-04T07:20:32Z"
    message: Valid GatewayClass
    observedGeneration: 1
    reason: Accepted
    status: "True"
    type: Accepted

[INFO] ✅ ALB Controller installed successfully!

[INFO] 📋 Next Steps:
    1. Run ./02-2-create-alb.sh to create the ALB subnet in AKS VNet
    2. Deploy your Gateway and HTTPRoute manifests
    3. Remember: ALB only supports ports 80 and 443 on listeners
```

## Check gatewayclasses again

```bash
➜ k get gatewayclass
NAME                 CONTROLLER                               ACCEPTED   AGE
azure-alb-external   alb.networking.azure.io/alb-controller   True       56s
```

## Deploy a gateway and httproute

```bash
➜ k apply -f manifests/infra/alb-gateway.yml
Error from server (NotFound): error when creating "manifests/infra/alb-gateway.yml": namespaces "alb-infra" not found
➜ k create namespace alb-infra
namespace/alb-infra created
➜ k apply -f manifests/infra/alb-gateway.yml
applicationloadbalancer.alb.networking.azure.io/alb-gateway created
➜ k get applicationloadbalancer -n alb-infra
NAME          DEPLOYMENT   AGE
alb-gateway   True         104s
```

## Deploy ping-pong application

```bash
➜ k create namespace exercises
namespace/exercises created
➜ export SOPS_AGE_KEY_FILE=$(pwd)/key.txt
➜ sops --decrypt ping-pong_application/manifests/secret.enc.yaml | k apply -f -
secret/ping-pong-secrets created
➜ k apply -f ping-pong_application/manifests/deployment.yaml -f ping-pong_application/manifests/service.yaml
configmap/ping-pong-config created
deployment.apps/ping-pong-deployment created
service/ping-pong-svc created
```

verify app is up and running

```bash
➜ k get pods -n exercises
NAME                                   READY   STATUS    RESTARTS   AGE
ping-pong-deployment-c485c5cf7-9bxjn   1/1     Running   0          48s
```

deploy gateway and httproute for the app

```bash
➜ k apply -f ping-pong_application/manifests/gateway.yaml -f ping-pong_application/manifests/route.yaml
gateway.gateway.networking.k8s.io/gateway-01 created
httproute.gateway.networking.k8s.io/my-route created
```


