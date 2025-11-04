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

# REMOVED OUTPUT

[INFO] Getting cluster credentials...
Merged "dwk-cluster" as current context in /Users/patrik/.kube/config
[INFO] Verifying cluster...
Kubernetes control plane is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-g5s2fuw1.hcp.northeurope.azmk8s.io:443
CoreDNS is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-g5s2fuw1.hcp.northeurope.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://dwk-cluste-rg-aks-mooc-001-56d9a5-g5s2fuw1.hcp.northeurope.azmk8s.io:443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
NAME                                STATUS   ROLES    AGE     VERSION
aks-nodepool1-29482853-vmss000000   Ready    <none>   2m14s   v1.32.7
aks-nodepool1-29482853-vmss000001   Ready    <none>   2m19s   v1.32.7
aks-nodepool1-29482853-vmss000002   Ready    <none>   2m10s   v1.32.7

[INFO] ✅ Cluster created successfully!

[STEP] Next steps:
  1. Run ./02-1-enable-alb.sh to install ALB Controller
  2. Then deploy your applications using Gateway and HTTPRoute

➜ KubernetesSubmissions ⚡( 52-exercise-33-to-the-gateway)                                                                                                                                                                                     5 hours ago
▶
```

## Install ALB controller

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

# REMOVED OUTPUT


[INFO] Waiting for identity replication and role assignments...
ERROR: Cannot find user or service principal in graph database for '9670314e-14b7-4dff-be50-f3d7d5d58855'. If the assignee is an appId, make sure the corresponding service principal is created with 'az ad sp create --id 9670314e-14b7-4dff-be50-f3d7d5d58855'.
[WARN]   Waiting for replication... (1/12)
ERROR: Cannot find user or service principal in graph database for '9670314e-14b7-4dff-be50-f3d7d5d58855'. If the assignee is an appId, make sure the corresponding service principal is created with 'az ad sp create --id 9670314e-14b7-4dff-be50-f3d7d5d58855'.
[WARN]   Waiting for replication... (2/12)
[WARN]   Waiting for replication... (3/12)
[WARN]   Waiting for replication... (4/12)
[WARN]   Waiting for replication... (5/12)
[WARN]   Waiting for replication... (6/12)
[WARN]   Waiting for replication... (7/12)
[WARN]   Waiting for replication... (8/12)
[WARN]   Waiting for replication... (9/12)
[WARN]   Waiting for replication... (10/12)
[WARN]   Waiting for replication... (11/12)
[WARN]   Waiting for replication... (12/12)
[INFO] Assigning Reader role to managed resource group...
# REMOVED OUTPUT
[INFO] Assigning AppGW for Containers Configuration Manager role...
# REMOVED OUTPUT
[INFO] Setting up OIDC federation...
# REMOVED OUTPUT
[INFO] Installing Gateway API CRDs...
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io created
[INFO] Installing ALB Controller via Helm...
Release "alb-controller" does not exist. Installing it now.
Pulled: mcr.microsoft.com/application-lb/charts/alb-controller:1.8.12
Digest: sha256:45ca59f05524e3e1aebd5413bea2c4119edc1900642f432eb670d00565aede65
NAME: alb-controller
LAST DEPLOYED: Tue Nov  4 13:23:40 2025
NAMESPACE: azure-alb-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Congratulations! The ALB Controller has been installed in your Kubernetes cluster!
[INFO] Waiting for ALB Controller pods to be ready (this may take 2-3 minutes)...

pod/alb-controller-b87bf5bb9-5hlr4 condition met
pod/alb-controller-b87bf5bb9-l8csg condition met
[INFO] Verifying controller pods...
NAME                             READY   STATUS    RESTARTS   AGE
alb-controller-b87bf5bb9-5hlr4   1/1     Running   0          30s
alb-controller-b87bf5bb9-l8csg   1/1     Running   0          30s
[INFO] Verifying GatewayClass...
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  creationTimestamp: "2025-11-04T12:23:55Z"
  generation: 1
  name: azure-alb-external
  resourceVersion: "3728"
  uid: d97fc9b2-4a7a-44b4-acb9-a44972660c73
spec:
  controllerName: alb.networking.azure.io/alb-controller
status:
  conditions:
  - lastTransitionTime: "2025-11-04T12:23:58Z"
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

## Deploy ALB gateway

```bash
➜ ./scripts/infrastructure/02-2-create-alb.sh
[STEP] Configuring ALB subnet for Application Gateway for Containers...

[INFO] 📋 Configuration to be applied:

  Azure Resources:
    • ALB Subnet: alb-subnet
      - VNet: vnet-dwk-cluster
      - Address Prefix: 10.225.0.0/24
      - Should already exist from network setup

    • Role Assignment:
      - Role: Network Contributor
      - Identity: azure-alb-identity
      - Scope: ALB subnet

[INFO] Verifying network infrastructure...
[INFO] Found ALB subnet:
[INFO]   • Name: alb-subnet
[INFO]   • Address: 10.225.0.0/24
[INFO]   • ID: /subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/alb-subnet
[INFO]   • Delegation: ✓ Properly delegated

[INFO] Assigning Network Contributor role to identity on ALB subnet...
{
  "condition": null,
  "conditionVersion": null,
  "createdBy": null,
  "createdOn": "2025-11-04T12:26:30.339801+00:00",
  "delegatedManagedIdentityResourceId": null,
  "description": null,
  "id": "/subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/alb-subnet/providers/Microsoft.Authorization/roleAssignments/99900bb0-baeb-4b14-8eae-72ef884c2c6d",
  "name": "99900bb0-baeb-4b14-8eae-72ef884c2c6d",
  "principalId": "9670314e-14b7-4dff-be50-f3d7d5d58855",
  "principalType": "ServicePrincipal",
  "resourceGroup": "rg-aks-mooc-001",
  "roleDefinitionId": "/subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7",
  "scope": "/subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/alb-subnet",
  "type": "Microsoft.Authorization/roleAssignments",
  "updatedBy": "5b1c9dfe-f803-4ceb-a771-61af1d4c478b",
  "updatedOn": "2025-11-04T12:26:30.482796+00:00"
}

[INFO] ✅ ALB subnet configured successfully!

[INFO] 📝 Network Topology:
    VNet: vnet-dwk-cluster (10.224.0.0/15)
    ├── AKS Subnet: aks-subnet (10.224.0.0/24) ← Nodes & pods
    └── ALB Subnet: alb-subnet (10.225.0.0/24) ← Application Gateway ✓

[INFO] 📝 Subnet Details:
    • Subnet ID: /subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/alb-subnet
    • Delegation: Microsoft.ServiceNetworking/trafficControllers ✓
    • RBAC: Network Contributor assigned to azure-alb-identity ✓

[INFO] 📋 Next Steps - Deploy using Managed ALB (Recommended):

    1. Create a namespace for ALB infrastructure:
       kubectl create namespace alb-infra

    2. Create ApplicationLoadBalancer resource (save as alb.yaml):

       apiVersion: alb.networking.azure.io/v1
       kind: ApplicationLoadBalancer
       metadata:
         name: alb-gateway
         namespace: alb-infra
       spec:
         associations:
         - /subscriptions/56d9a591-8bfe-40fb-96a4-17b3ec30d23a/resourceGroups/rg-aks-mooc-001/providers/Microsoft.Network/virtualNetworks/vnet-dwk-cluster/subnets/alb-subnet

    3. Apply it:
       kubectl apply -f alb.yaml

    4. Create your Gateway (save as gateway.yaml):

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

    5. Create HTTPRoute for your services

    Note: The ALB controller will automatically create the Azure ALB resource
          and configure it based on your Gateway and HTTPRoute manifests.
```

## Create namespaces

```bash
➜ ./scripts/infrastructure/03-1-create-namespaces.sh
namespace/exercises created
namespace/alb-infra created
namespace/database created
namespace/monitoring created
namespace/project created
```

## Deploy the ALB gateway

```bash
➜ k apply -f manifests/infra/alb.yml
applicationloadbalancer.alb.networking.azure.io/alb-gateway created
```

## Deploy ping pong application with gateway

```bash
➜ k apply -f manifests/infra/alb.yml
applicationloadbalancer.alb.networking.azure.io/alb-gateway created
➜ export SOPS_AGE_KEY_FILE=$(pwd)/key.txt
➜ sops --decrypt ping-pong_application/manifests/secret.enc.yaml | k apply -f -
secret/ping-pong-secrets created
➜ k apply -f ping-pong_application/manifests/deployment.yaml -f ping-pong_application/manifests/service.yaml
configmap/ping-pong-config created
deployment.apps/ping-pong-deployment created
service/ping-pong-svc created
➜ k apply -f ping-pong_application/manifests/gateway.yaml -f ping-pong_application/manifests/route.yaml -f ping-pong_application/manifests/healthcheck.yml
gateway.gateway.networking.k8s.io/gateway-01 created
httproute.gateway.networking.k8s.io/my-route created
healthcheckpolicy.alb.networking.azure.io/ping-pong-health created
```

Now its time to wait for everything to come up and get the public IP from the ALB gateway.

```bash
➜ k get gatewayClass
NAME                 CONTROLLER                               ACCEPTED   AGE
azure-alb-external   alb.networking.azure.io/alb-controller   True       11m

➜ k get gateway -A
NAMESPACE   NAME         CLASS                ADDRESS   PROGRAMMED   AGE
exercises   gateway-01   azure-alb-external             Unknown      99s

➜ k get gateway -A
NAMESPACE   NAME         CLASS                ADDRESS                               PROGRAMMED   AGE
exercises   gateway-01   azure-alb-external   dmhcc6axe4cueece.fz43.alb.azure.com   True         4m2s
```

Now the gateway is up and running. Test it by curling the address:

```bash
➜ curl -i http://dmhcc6axe4cueece.fz43.alb.azure.com/pingpong
HTTP/1.1 200 OK
date: Tue, 04 Nov 2025 12:35:06 GMT
server: Microsoft-Azure-Application-LB/AGC
content-length: 51
content-type: application/json

{"message":"pong 0","counter":0,"storage":"memory"}%
```
