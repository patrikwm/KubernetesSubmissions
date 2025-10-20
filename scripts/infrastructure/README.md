# Infrastructure Setup Scripts

Scripts for setting up Azure Kubernetes Service (AKS) with Application Gateway for Containers (ALB) in **North Europe**.

## 🚀 Quick Start

```bash
# 0. Validate network configuration (optional but recommended)
./00-0-check-network-config.sh

# 1. Create network infrastructure (VNet + subnets)
./00-1-create-network.sh

# 2. Create AKS cluster in the network
./00-2-create-cluster.sh

# 3. Install ALB Controller
./02-1-enable-alb.sh

# 4. Configure ALB subnet permissions
./02-2-create-alb.sh

# 5. Verify setup
./verify-alb-setup.sh
```

Then follow the deployment instructions in `QUICK-START.sh`.

## 📁 Files

| File | Purpose |
|------|---------|
| `config.sh` | Shared configuration (region, resource names, **network settings**) |
| `00-0-check-network-config.sh` | **Validates network configuration (sanity checks)** |
| `00-1-create-network.sh` | **Creates VNet and subnets (run first!)** |
| `00-2-create-cluster.sh` | Creates AKS cluster in pre-created network |
| `01-1-enable-ingress.sh` | Enables NGINX ingress (alternative to ALB) |
| `02-1-enable-alb.sh` | Installs ALB Controller with proper RBAC |
| `02-2-create-alb.sh` | Configures ALB subnet permissions |
| `verify-alb-setup.sh` | Verifies all prerequisites are met |
| `cleanup.sh` | Deletes all resources |
| `QUICK-START.sh` | Quick reference for deployment |
| `CHANGES-SUMMARY.md` | Summary of recent updates |
| `ALB-SETUP-NOTES.md` | Detailed technical documentation |
| `NETWORK-PLANNING.md` | **Network architecture and sizing guide** |

## ⚙️ Configuration

All network and cluster settings are centralized in `config.sh`:

```bash
# Core settings
export RESOURCE_GROUP="rg-aks-mooc-001"
export AKS_NAME="dwk-cluster"
export LOCATION="northeurope"
export SUBSCRIPTION_ID='your-subscription-id'

# Network configuration (defined once, used everywhere)
export VNET_NAME="vnet-dwk-cluster"
export VNET_CIDR="10.224.0.0/15"        # Spans both 10.224.x.x and 10.225.x.x
export AKS_SUBNET_NAME="aks-subnet"
export AKS_SUBNET_CIDR="10.224.0.0/24"  # Nodes & pods
export ALB_SUBNET_NAME="alb-subnet"
# AKS service networking (separate from VNet to avoid overlap)
export SERVICE_CIDR="10.226.0.0/16"     # Kubernetes services (ClusterIP, etc.)
export DNS_SERVICE_IP="10.226.0.10"     # Must be within SERVICE_CIDR
export DOCKER_BRIDGE_CIDR="172.17.0.1/16" # Docker bridge network
```

**Why centralize network config?**
- Consistent across all scripts
- Easy to adjust if needed
- No hardcoded values scattered in scripts
- Clear single source of truth
- Includes service networking to avoid overlaps

**Address Space Allocation:**
- `10.224.x.x - 10.225.x.x`: VNet (nodes, pods, ALB)
- `10.226.x.x`: Kubernetes services (ClusterIP)
- `172.17.x.x`: Docker bridge

## 🔧 Scripts in Detail

### 00-0-check-network-config.sh ⭐ NEW
**Optional but recommended - run before creating anything!**

Validates network configuration:
- Checks VNet contains both AKS and ALB subnets
- Ensures Service CIDR doesn't overlap with VNet
- Validates DNS IP is within Service CIDR
- Verifies Docker bridge is separate
- Shows clear summary of address allocation

**No Azure resources needed** - pure validation logic.

### 00-1-create-network.sh
**Run this FIRST!**

Creates the complete network infrastructure:
- **VNet:** `10.224.0.0/15` (131,072 IPs)
- **AKS Subnet:** `10.224.0.0/24` (256 IPs) for nodes and pods
- **ALB Subnet:** `10.225.0.0/24` (256 IPs) delegated to `Microsoft.ServiceNetworking/trafficControllers`

**Improvements:**
- ✅ Additive VNet address space updates (doesn't replace)
- ✅ Uses `--only-show-errors` for clean output
- ✅ Idempotent (safe to run multiple times)
- ✅ Verifies subnet delegation

**Why create network first:**
- Deterministic IP addressing (no surprises)
- ALB subnet ready from day one
- Follows Azure best practices (BYO network)
- Easier troubleshooting

### 00-2-create-cluster.sh
Creates AKS cluster with:
- **Region:** North Europe (required for ALB)
- **Network:** Uses pre-created VNet and AKS subnet via `--vnet-subnet-id`
- **Network Plugin:** Azure CNI (pods get IPs from subnet)
- **Dataplane:** Cilium (modern eBPF-based dataplane)
- **Service Networking:** Explicit service CIDR, DNS IP, Docker bridge
- **Features:** OIDC Issuer, Workload Identity
- **Nodes:** 3x Standard_B2s

**Improvements:**
- ✅ Explicit service networking (no overlaps)
- ✅ Cilium dataplane for better performance
- ✅ Conditional Azure login (no prompts if already logged in)
- ✅ Uses `--only-show-errors` throughout
- ✅ Shows service CIDR info before creation

**Requires:** Network must exist (run `00-1-create-network.sh` first)

### 00-create-cluster.sh
Creates AKS cluster with:
- **Region:** North Europe (required for ALB)
- **Network:** Uses pre-created VNet and AKS subnet via `--vnet-subnet-id`
- **Network Plugin:** Azure CNI (pods get IPs from subnet)
- **Features:** OIDC Issuer, Workload Identity
- **Nodes:** 3x Standard_B2s

**Requires:** Network must exist (run `00-create-network.sh` first)

### 02-1-enable-alb.sh
Installs ALB Controller:
- Creates managed identity
- Assigns **3 RBAC roles**:
  - Reader (on managed RG)
  - AppGW Configuration Manager (on managed RG)
  - Network Contributor (on ALB subnet - done in 02-2)
- Sets up OIDC federation
- Installs Gateway API CRDs
- Installs Helm chart (v1.7.12)

### 02-2-create-alb.sh
Configures ALB subnet permissions:
- Verifies ALB subnet exists and is properly delegated
- Assigns Network Contributor role on subnet to managed identity
- **Much simpler now** since network is pre-created

**Requires:** Network created, ALB Controller installed

### verify-alb-setup.sh
Checks:
- ✓ Cluster in correct region
- ✓ OIDC and Workload Identity enabled
- ✓ Managed identity exists
- ✓ All RBAC roles assigned
- ✓ ALB Controller pods running
- ✓ GatewayClass created
- ✓ ALB subnet configured

## 📊 Network Architecture

```
Azure Region: North Europe
│
├── Resource Group: rg-aks-mooc-001
│   ├── AKS Cluster: dwk-cluster
│   └── Managed Identity: azure-alb-identity
│
└── Managed Resource Group: MC_rg-aks-mooc-001_dwk-cluster_northeurope
    └── VNet (10.224.0.0/15)  ← /15 to include both 10.224.x.x and 10.225.x.x
        ├── Cluster Subnet (10.224.0.0/24)  ← Nodes & Pods (min /27, recommended /24)
        └── ALB Subnet (10.225.0.0/24)      ← Application Gateway
            └── Delegated to Microsoft.ServiceNetworking/trafficControllers
```

## 🔐 RBAC Permissions

The managed identity `azure-alb-identity` has:

| Role | Scope | Purpose |
|------|-------|---------|
| Reader | Managed RG | Read cluster resources |
| AppGW Configuration Manager | Managed RG | Create/modify ALB |
| Network Contributor | ALB subnet | Join subnet, configure networking |

## 🎯 Usage Example

After running the setup scripts:

```bash
# Create namespace
kubectl create namespace alb-infra

# Deploy ApplicationLoadBalancer (use subnet ID from 02-2 output)
cat <<EOF | kubectl apply -f -
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb-demo
  namespace: alb-infra
spec:
  associations:
  - /subscriptions/.../subnets/alb-subnet
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

# Create HTTPRoute
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
spec:
  parentRefs:
  - name: gateway-01
  rules:
  - backendRefs:
    - name: my-service
      port: 8080
EOF

# Check status
kubectl get gateway,httproute
```

## ⚠️ Important Notes

### Region Requirement
**ALB is NOT available in Sweden Central.** Your cluster must be in:
- ✅ North Europe
- ✅ West Europe
- ✅ Or other supported regions

### Port Restrictions
ALB **only supports ports 80 and 443** on listeners.

### Subnet Address Space
- **AKS Subnet:** `10.224.0.0/24` (minimum `/27`, recommended `/24` for Azure CNI)
- **ALB Subnet:** `10.225.0.0/24`
- **VNet Range:** Must be at least `/15` to include both subnets

If your VNet uses a different range, you have two options:
1. **Expand VNet** to `/15` to accommodate `10.224.x.x` and `10.225.x.x`
2. **Adjust ALB subnet** to fit within your existing VNet (e.g., `10.224.1.0/24`)

Edit `ALB_SUBNET_PREFIX` in `02-2-create-alb.sh` if needed.

### Managed vs BYO
These scripts use the **Managed** approach:
- You create the subnet
- You create ApplicationLoadBalancer CR
- Controller creates Azure ALB automatically

This is simpler than the BYO (Bring Your Own) approach.

## 🔍 Troubleshooting

### Verify Setup
```bash
./verify-alb-setup.sh
```

### Check Controller Logs
```bash
kubectl logs -n azure-alb-system -l app=alb-controller
```

### Check Gateway Status
```bash
kubectl describe gateway gateway-01
```

### Check RBAC
```bash
principalId=$(az identity show -g rg-aks-mooc-001 -n azure-alb-identity --query principalId -o tsv)
az role assignment list --assignee $principalId --output table
```

### Common Issues

**Gateway stuck in "Pending":**
- Check controller logs
- Verify all 3 RBAC roles assigned
- Ensure subnet is properly delegated

**"ALB not available in region":**
- Verify cluster is in North/West Europe
- Run `./verify-alb-setup.sh`

**Can't reach services:**
- Check HTTPRoute configuration
- Verify backend service exists
- Check service has endpoints

## 📚 Documentation

- **BYO-NETWORK.md** - Why we create network first (BYO approach) ⭐ NEW
- **NETWORK-PLANNING.md** - Network architecture and subnet sizing guide
- **ALB-SETUP-NOTES.md** - Detailed technical documentation
- **CHANGES-SUMMARY.md** - What changed from old scripts
- **QUICK-START.sh** - Quick reference commands

## 🧹 Cleanup

To delete all resources:

```bash
./cleanup.sh
```

This will:
1. Delete the AKS cluster
2. Delete the resource group
3. Remove local kubectl context

## 📖 References

- [Application Gateway for Containers Docs](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview)
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)

## 🆘 Need Help?

1. Run `./verify-alb-setup.sh` to check configuration
2. Check controller logs: `kubectl logs -n azure-alb-system -l app=alb-controller`
3. See detailed docs in `ALB-SETUP-NOTES.md`
4. Review what changed in `CHANGES-SUMMARY.md`

---

**Key Takeaway:** These scripts set up a complete ALB infrastructure in North Europe with proper networking (same VNet) and all required RBAC permissions. After running them, you can deploy Gateway and HTTPRoute resources to route traffic to your services.
