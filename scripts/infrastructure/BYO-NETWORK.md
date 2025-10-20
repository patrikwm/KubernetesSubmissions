# BYO Network Approach - Summary

## What Changed

Updated the infrastructure setup to follow Azure best practices: **Create the network infrastructure FIRST, then deploy AKS into it.**

## Why This Matters

### The Old Way (Let AKS Create Network)
```bash
./00-create-cluster.sh  # AKS creates managed VNet
./02-2-create-alb.sh    # Try to add ALB subnet later
```

**Problems:**
- ❌ Address space might not fit ALB subnet
- ❌ Need to find and modify managed VNet
- ❌ Less control over IP ranges
- ❌ Harder to troubleshoot
- ❌ Potential for address conflicts

### The New Way (BYO Network)
```bash
./00-create-network.sh  # Create VNet + subnets first
./00-create-cluster.sh  # Deploy AKS into pre-created network
./02-1-enable-alb.sh    # Install ALB controller
./02-2-create-alb.sh    # Configure ALB subnet (already exists!)
```

**Benefits:**
- ✅ Deterministic IP addressing
- ✅ ALB subnet ready from day one
- ✅ Full control over network topology
- ✅ Follows Azure best practices
- ✅ Easier to validate and troubleshoot
- ✅ Works across multiple clusters if needed

## Changes Made

### 1. New Script: `00-create-network.sh`

Creates complete network infrastructure:

```bash
VNet: 10.224.0.0/15
├── aks-subnet: 10.224.0.0/24  (for AKS)
└── alb-subnet: 10.225.0.0/24  (for ALB, delegated)
```

**Features:**
- Idempotent (safe to run multiple times)
- Validates existing configuration
- Can update VNet address space if needed
- Checks subnet delegation
- Clear logging of what's being created

### 2. Updated: `config.sh`

Added centralized network configuration:

```bash
# Network configuration (used by all scripts)
export VNET_NAME="vnet-dwk-cluster"
export VNET_CIDR="10.224.0.0/15"
export AKS_SUBNET_NAME="aks-subnet"
export AKS_SUBNET_CIDR="10.224.0.0/24"
export ALB_SUBNET_NAME="alb-subnet"
export ALB_SUBNET_CIDR="10.225.0.0/24"
```

**Why centralize:**
- Single source of truth
- Consistent across all scripts
- Easy to adjust if needed
- No hardcoded values

### 3. Updated: `00-create-cluster.sh`

Now uses pre-created network:

```bash
# Old: AKS creates its own VNet
az aks create \
  --network-plugin azure

# New: AKS uses pre-created VNet
az aks create \
  --vnet-subnet-id "$AKS_SUBNET_ID" \
  --network-plugin azure
```

**Added:**
- Validation that network exists
- Clear error if network not found
- Uses subnet ID from config

### 4. Simplified: `02-2-create-alb.sh`

Much simpler now:

**Before:**
- Find AKS VNet from managed resource group
- Check address space compatibility
- Offer to expand VNet if needed
- Create ALB subnet
- Delegate subnet
- ~100 lines of complexity

**After:**
- Verify network exists (from config)
- Check ALB subnet exists and is delegated
- Assign RBAC
- ~30 lines, clear and simple

### 5. Updated Documentation

- **README.md** - Updated workflow, added network script
- **ALB-SETUP-NOTES.md** - Added Step 0 for network creation
- **QUICK-START.sh** - Updated to include network creation first
- All docs reflect BYO network approach

## New Workflow

### Complete Setup from Scratch

```bash
# 1. Create network infrastructure
./00-create-network.sh
# Output: VNet + 2 subnets created

# 2. Create AKS cluster in the network
./00-create-cluster.sh
# Output: Cluster deployed into aks-subnet

# 3. Install ALB controller
./02-1-enable-alb.sh
# Output: Controller installed with RBAC

# 4. Configure ALB subnet
./02-2-create-alb.sh
# Output: Subnet permissions configured

# 5. Verify everything
./verify-alb-setup.sh
# Output: All checks pass ✓
```

### If Network Already Exists

The scripts are idempotent and will:
- Detect existing VNet
- Validate configuration
- Offer to fix if something's wrong
- Skip if already correct

## Azure Best Practices Alignment

This approach aligns with Microsoft's recommendations:

1. **Bring Your Own Network** - Create VNet before cluster ✓
2. **Proper Subnet Sizing** - `/24` for AKS, `/24` for ALB ✓
3. **Delegation** - ALB subnet delegated at creation time ✓
4. **L3 Connectivity** - Both subnets in same VNet ✓
5. **RBAC** - Permissions assigned to correct scopes ✓

## Benefits in Practice

### Easier Troubleshooting

**Before:**
```
"Where's my VNet?"
→ Check managed resource group
→ Find generated name like "MC_rg-aks_cluster_region"
→ Address space might be 10.224.0.0/16
→ Can't fit 10.225.0.0/24
→ Need to expand VNet
→ Hope nothing breaks
```

**After:**
```
"Where's my VNet?"
→ It's called vnet-dwk-cluster in rg-aks-mooc-001
→ Address space is exactly 10.224.0.0/15
→ Both subnets fit perfectly
→ Everything is where config.sh says it is
```

### Multi-Cluster Scenarios

With BYO network, you can:
- Share a VNet across multiple clusters
- Add more subnets for different purposes
- Implement hub-spoke topology
- Use VNet peering effectively

### Infrastructure as Code

Network configuration in `config.sh` makes it easy to:
- Version control your network design
- Replicate in different environments
- Adjust ranges for different scenarios
- Document your decisions

## Migration Guide

**If you haven't created a cluster yet:**
- Just use the new workflow (network first!)

**If you have an existing cluster:**

Option 1: Keep using it (it works)
- Network is already there
- `02-2-create-alb.sh` will find and use it
- Just understand it's managed by AKS

Option 2: Recreate with BYO network
- Delete cluster (keep apps backed up)
- Run `./00-create-network.sh`
- Run `./00-create-cluster.sh`
- Redeploy apps
- Benefit: Full control going forward

## Configuration Reference

All network settings are in `config.sh`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `VNET_NAME` | `vnet-dwk-cluster` | VNet name |
| `VNET_CIDR` | `10.224.0.0/15` | VNet address space (131k IPs) |
| `AKS_SUBNET_NAME` | `aks-subnet` | AKS nodes/pods subnet name |
| `AKS_SUBNET_CIDR` | `10.224.0.0/24` | AKS subnet range (256 IPs) |
| `ALB_SUBNET_NAME` | `alb-subnet` | ALB subnet name |
| `ALB_SUBNET_CIDR` | `10.225.0.0/24` | ALB subnet range (256 IPs) |

**To customize:**
1. Edit `config.sh`
2. Ensure ranges don't overlap
3. VNet CIDR must include both subnet ranges
4. Run `./00-create-network.sh`

## Summary

✅ **Network created first** - Deterministic, controlled, predictable
✅ **Config centralized** - Single source of truth in `config.sh`
✅ **Scripts simplified** - Less complexity, easier to understand
✅ **Best practices** - Follows Microsoft's BYO network recommendations
✅ **Idempotent** - Safe to run multiple times
✅ **Clear workflow** - Network → Cluster → ALB Controller → Configure

The infrastructure setup is now **cleaner, more maintainable, and follows Azure best practices**! 🎉
