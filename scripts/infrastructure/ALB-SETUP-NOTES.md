# Application Load Balancer (ALB) Setup - Updated for North Europe

## Overview of Changes

All scripts have been updated to properly support Azure Application Gateway for Containers (ALB). The main changes address region compatibility, networking topology, RBAC permissions, and use current versions.

## Key Changes Made

### 1. **Region Change: Sweden Central → North Europe**

**File:** `config.sh`

- Changed `LOCATION="swedencentral"` to `LOCATION="northeurope"`
- **Why:** ALB is not available in Sweden Central. The AKS cluster itself must be in a supported region (North Europe, West Europe, etc.)
- **Impact:** All resources (cluster, VNet, ALB) will now be created in North Europe

### 2. **Cluster Configuration Updates**

**File:** `00-create-cluster.sh`

- Removed fixed Kubernetes version pin (`--kubernetes-version 1.32.0`)
- Reduced node count from 5 to 3 (sufficient for labs)
- Added location confirmation log message
- **Why:** Version pins can cause "unsupported version" errors; letting Azure choose ensures you get a supported version

### 3. **ALB Controller Installation - Major Updates**

**File:** `02-1-enable-alb.sh`

#### Helm Chart Version Update
- Updated from version `1.0.0` to `1.7.12`
- Changed Helm namespace to `azure-alb-helm` (cleaner separation)
- **Why:** Version 1.0.0 is very old; 1.7.12 has important fixes and features

#### RBAC Fixes - Added Missing Role
Previously only assigned **Reader** role. Now assigns:

1. **Reader** (`acdd72a7-3385-48ef-bd42-f606fba81ae7`) - Already existed
2. **AppGW for Containers Configuration Manager** (`fbc52c3f-28ad-4303-a892-8a056630b8f1`) - **NEW**

**Why:** The controller needs Configuration Manager role to actually create/modify ALB resources.

#### Removed Incorrect Warnings
- Removed warnings about "cluster needs to be in another region"
- **Why:** Cluster is now in North Europe, so ALB will work

### 4. **ALB Subnet Creation - Complete Rewrite**

**File:** `02-2-create-alb.sh`

This is the biggest change - completely rewrote the approach:

#### Old Approach (BYO - Bring Your Own)
- Created a separate VNet for ALB
- Created ALB resource via CLI
- **Problem:** Separate VNet has no connectivity to AKS pods

#### New Approach (Managed, in AKS VNet)
1. **Finds the existing AKS VNet** automatically
2. **Creates ALB subnet inside the AKS VNet**
   - Delegates to `Microsoft.ServiceNetworking/trafficControllers`
   - Uses address prefix `10.225.0.0/24`
3. **Assigns Network Contributor role** on the subnet to the managed identity
4. **Provides instructions for Managed ALB deployment** via Kubernetes

**Why these changes:**
- **Connectivity:** ALB in same VNet can reach pods directly
- **Simplicity:** No VNet peering needed
- **Recommended:** Microsoft recommends Managed approach over BYO
- **RBAC:** Network Contributor on subnet is required for ALB to work

## Network Topology

```
AKS VNet (10.224.0.0/15)  ← Expanded to /15 to include both subnets
├── AKS Subnet (10.224.0.0/24)  ← Cluster nodes & pods (recommended /24, min /27)
└── ALB Subnet (10.225.0.0/24)  ← Application Gateway for Containers
    └── Delegated to Microsoft.ServiceNetworking/trafficControllers
```

Both subnets in same VNet = direct connectivity ✅

**Important:** The VNet must be `/15` (or larger) to accommodate both the `10.224.x.x` and `10.225.x.x` address spaces.

## RBAC Summary

The managed identity `azure-alb-identity` needs these roles:

| Role | Scope | Purpose |
|------|-------|---------|
| Reader | AKS managed RG | Read cluster resources |
| AppGW Configuration Manager | AKS managed RG | Create/modify ALB resources |
| Network Contributor | ALB subnet | Join subnet, configure networking |

All three are now properly assigned.

## Usage Instructions

### Network Planning

**⚠️ Important:** Before running the scripts, understand the network requirements.

See **[NETWORK-PLANNING.md](NETWORK-PLANNING.md)** for detailed guidance on:
- VNet sizing (must be `/15` or adjust ALB subnet)
- Subnet requirements (AKS min `/27`, recommended `/24`)
- Address space planning
- Alternative configurations

**TL;DR:** Default config uses:
- VNet: `10.224.0.0/15` (must be `/15` to include both subnets)
- AKS Subnet: `10.224.0.0/24`
- ALB Subnet: `10.225.0.0/24`

## Quick Verification

After running the scripts, verify everything is set up correctly:

```bash
./verify-alb-setup.sh
```

This checks:
- ✓ Cluster region (must be North/West Europe)
- ✓ OIDC and Workload Identity enabled
- ✓ Managed identity exists
- ✓ All 3 RBAC roles assigned
- ✓ ALB Controller pods running
- ✓ GatewayClass exists
- ✓ ALB subnet created and delegated

## Step 0: Create Network Infrastructure ⭐ NEW
**Run this FIRST!**

```bash
./00-create-network.sh
```

This creates:
- VNet with `/15` address space to accommodate both subnets
- AKS subnet (`10.224.0.0/24`) for cluster nodes and pods
- ALB subnet (`10.225.0.0/24`) with proper delegation to `Microsoft.ServiceNetworking/trafficControllers`

**Why create network first:**
- Deterministic IP addressing (you control the ranges)
- ALB subnet is ready from day one
- Follows Azure best practices (BYO network)
- Easier troubleshooting and validation

## Step 1: Create the Cluster
```bash
./00-create-cluster.sh
```
- Creates cluster in North Europe
- Uses pre-created VNet and AKS subnet (via `--vnet-subnet-id`)
- Network plugin: Azure CNI (pods get IPs from subnet)
- Enables OIDC and Workload Identity (required for ALB)

### Step 2: Install ALB Controller
```bash
./02-1-enable-alb.sh
```
- Installs latest ALB controller (v1.7.12)
- Creates managed identity with proper RBAC
- Sets up OIDC federation
- Installs Gateway API CRDs
- Creates `azure-alb-external` GatewayClass

### Step 3: Configure ALB Subnet
```bash
./02-2-create-alb.sh
```
- Verifies ALB subnet exists and is properly delegated
- Assigns Network Contributor role on subnet to managed identity
- Provides deployment instructions
- **Note:** Much simpler now since network is pre-created!

### Step 4: Deploy ALB via Kubernetes (Managed Approach)

#### Create ALB Infrastructure Namespace
```bash
kubectl create namespace alb-infra
```

#### Create ApplicationLoadBalancer Resource
```yaml
# alb.yaml
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb-demo
  namespace: alb-infra
spec:
  associations:
  - /subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/alb-subnet
```

Get the subnet ID from the output of `02-2-create-alb.sh`.

```bash
kubectl apply -f alb.yaml
```

#### Create Gateway
```yaml
# gateway.yaml
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
```

```bash
kubectl apply -f gateway.yaml
```

#### Create HTTPRoute
```yaml
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
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
```

```bash
kubectl apply -f httproute.yaml
```

## Important Notes

### Port Restrictions
ALB **only supports ports 80 and 443** on listeners. Don't try to use other ports.

### Address Space
The ALB subnet uses `10.225.0.0/24`. This requires the VNet to be at least `/15` to include both:
- `10.224.0.0/24` (AKS nodes and pods)
- `10.225.0.0/24` (ALB)

If your existing VNet uses a different range:
1. Check current VNet range: `az network vnet show -g <rg> -n <vnet> --query addressSpace`
2. If needed, expand it to `/15` or adjust `ALB_SUBNET_PREFIX` in `02-2-create-alb.sh` to fit within your VNet range (e.g., `10.224.1.0/24`)

### Managed vs BYO
The updated scripts use the **Managed approach** where:
- You create the delegated subnet
- You create `ApplicationLoadBalancer` CR in Kubernetes
- The controller creates the actual Azure ALB resource automatically

This is simpler and better documented than the BYO approach.

## Troubleshooting

### Check Controller Pods
```bash
kubectl get pods -n azure-alb-system
kubectl logs -n azure-alb-system -l app=alb-controller
```

### Check GatewayClass
```bash
kubectl get gatewayclass azure-alb-external -o yaml
```

### Check Gateway Status
```bash
kubectl get gateway gateway-01 -o yaml
kubectl describe gateway gateway-01
```

### Check ApplicationLoadBalancer
```bash
kubectl get applicationloadbalancer -n alb-infra
kubectl describe applicationloadbalancer alb-demo -n alb-infra
```

### Common Issues

1. **"ALB not available in region"**
   - Verify cluster is in North Europe: `az aks show -g rg-aks-mooc-001 -n dwk-cluster --query location`

2. **Gateway stays in "Pending" status**
   - Check controller logs
   - Verify RBAC assignments: `az role assignment list --assignee <principal-id>`
   - Ensure subnet is properly delegated

3. **Can't reach services**
   - Check HTTPRoute is correctly configured
   - Verify backend service exists and has endpoints
   - Check NSG rules (shouldn't be an issue in same VNet)

## References

- [ALB Documentation](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview)
- [Gateway API Docs](https://gateway-api.sigs.k8s.io/)
- [ALB Controller GitHub](https://github.com/Azure/application-gateway-kubernetes-ingress)
