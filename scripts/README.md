# KubernetesSubmissions Scripts

Organized scripts for managing AKS cluster lifecycle and application deployments for lab work.

## 📁 Directory Structure

```
scripts/
├── infrastructure/          # Cluster lifecycle & features
│   ├── config.sh           # Shared configuration
│   ├── 00-create-cluster.sh
│   ├── 01-enable-ingress.sh
│   ├── 02-enable-alb.sh
│   └── cleanup.sh
│
├── apps/                    # Application deployments
│   ├── deploy-postgres.sh
│   ├── deploy-ping-pong.sh
│   ├── deploy-log-output.sh
│   ├── deploy-todo-app.sh
│   └── deploy-todo-backend.sh
│
└── dev/                     # Development utilities
    ├── setup-venv.sh
    ├── port-forward.sh
    └── run-tests.sh
```

## 🚀 Quick Start Guide

### 1. Create Cluster

```bash
cd scripts/infrastructure
./00-create-cluster.sh
```

This creates an AKS cluster with:
- 5 nodes (Standard_B2s)
- 32GB disk per node
- OIDC issuer enabled
- Workload identity enabled

**Time:** ~5-10 minutes

### 2. Enable App Routing (NGINX Ingress)

```bash
./01-enable-ingress.sh
```

This enables the Azure-managed NGINX ingress controller.

**Recommended:** Use this for the Sweden Central cluster.

### 3. (Optional) Enable Application Gateway for Containers

```bash
./02-enable-alb.sh
```

⚠️ **Warning:** ALB is NOT available in Sweden Central. Only use if cluster is in North/West Europe.

### 4. Deploy Applications

```bash
cd ../apps

# Deploy database first
./deploy-postgres.sh

# Deploy ping-pong app (requires postgres)
./deploy-ping-pong.sh

# Deploy other apps
./deploy-log-output.sh
./deploy-todo-app.sh
./deploy-todo-backend.sh
```

### 5. Develop Locally

```bash
cd ../dev

# Set up Python virtual environment
./setup-venv.sh

# Activate venv
source ../../.venv/bin/activate

# Port-forward a service for local testing
./port-forward.sh exercises ping-pong-svc 8080:80

# In another terminal: test the app
curl http://localhost:8080/pingpong
```

### 6. End of Day Cleanup

```bash
cd ../infrastructure
./cleanup.sh
```

⚠️ **This deletes EVERYTHING!** Type 'yes' to confirm.

## 📖 Detailed Usage

### Infrastructure Scripts

#### Configuration (`config.sh`)

Shared variables for all infrastructure scripts:
- `RESOURCE_GROUP`: rg-aks-mooc-001
- `AKS_NAME`: dwk-cluster
- `LOCATION`: swedencentral
- `SUBSCRIPTION_ID`: Your Azure subscription

Edit this file to change cluster settings.

#### Create Cluster (`00-create-cluster.sh`)

Creates the base AKS cluster.

```bash
./00-create-cluster.sh
```

**What it does:**
- Logs into Azure
- Registers resource providers
- Creates AKS cluster
- Gets credentials
- Verifies cluster

#### Enable Ingress (`01-enable-ingress.sh`)

Enables Azure-managed NGINX ingress (recommended).

```bash
./01-enable-ingress.sh
```

**What it does:**
- Enables app routing addon
- Waits for ingress controller pods
- Verifies ingress class `webapprouting.kubernetes.azure.com`

#### Enable ALB (`02-enable-alb.sh`)

Installs Application Gateway for Containers controller.

```bash
./02-enable-alb.sh
```

⚠️ **Region Limitation:** Only works in: northeurope, westeurope, eastus, westus, etc.
Sweden Central is NOT supported.

#### Cleanup (`cleanup.sh`)

Deletes the entire cluster and all resources.

```bash
./cleanup.sh
```

**What it does:**
- Prompts for confirmation
- Uninstalls ALB controller
- Removes role assignments
- Deletes managed identity
- Deletes AKS cluster (background)

### Application Scripts

All app scripts support `delete` argument:

```bash
./deploy-postgres.sh delete
./deploy-ping-pong.sh delete
```

#### Deploy Postgres (`deploy-postgres.sh`)

Deploys PostgreSQL StatefulSet to `database` namespace.

```bash
./deploy-postgres.sh         # Deploy
./deploy-postgres.sh delete  # Delete
```

#### Deploy Ping-Pong (`deploy-ping-pong.sh`)

Deploys the ping-pong application with ingress.

```bash
./deploy-ping-pong.sh         # Deploy
./deploy-ping-pong.sh delete  # Delete
```

**Requirements:** Postgres must be running.

**Endpoints:**
- `/pingpong` - Increment counter
- `/pings` - Get ping count

#### Deploy Log Output (`deploy-log-output.sh`)

Deploys the log-output application.

```bash
./deploy-log-output.sh         # Deploy
./deploy-log-output.sh delete  # Delete
```

#### Deploy Todo App (`deploy-todo-app.sh`)

Deploys the todo frontend application.

```bash
./deploy-todo-app.sh         # Deploy
./deploy-todo-app.sh delete  # Delete
```

#### Deploy Todo Backend (`deploy-todo-backend.sh`)

Deploys the todo backend with CronJob.

```bash
./deploy-todo-backend.sh         # Deploy
./deploy-todo-backend.sh delete  # Delete
```

**Requirements:** Postgres must be running.

### Development Scripts

#### Setup Virtual Environment (`setup-venv.sh`)

Creates and populates Python virtual environment.

```bash
./setup-venv.sh
```

**What it does:**
- Creates `.venv` directory
- Installs all Python dependencies
- Shows activation instructions

#### Port Forward (`port-forward.sh`)

Forward a Kubernetes service to localhost.

```bash
./port-forward.sh <namespace> <service> [local:remote]
```

**Examples:**

```bash
# Ping-pong app
./port-forward.sh exercises ping-pong-svc 8080:80

# Postgres database
./port-forward.sh database postgres-svc 5432:5432

# Log output
./port-forward.sh exercises log-output-svc 9000:80
```

#### Run Tests (`run-tests.sh`)

Runs test files for all applications.

```bash
./run-tests.sh
```

## 🎯 Common Workflows

### Fresh Start (Day 1)

```bash
# 1. Create infrastructure
cd scripts/infrastructure
./00-create-cluster.sh
./01-enable-ingress.sh

# 2. Deploy apps
cd ../apps
./deploy-postgres.sh
./deploy-ping-pong.sh

# 3. Test
INGRESS_IP=$(kubectl get ingress -n exercises -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
curl http://$INGRESS_IP/pingpong
```

### Add New Application

```bash
cd scripts/apps
./deploy-log-output.sh
```

### Development Session

```bash
# Set up environment
cd scripts/dev
./setup-venv.sh
source ../../.venv/bin/activate

# Make code changes in your editor
cd ../../ping-pong_application
# Edit files...

# Test locally
export DATA_ROOT=../shared
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
# ... other env vars

# In another terminal: forward postgres
cd scripts/dev
./port-forward.sh database postgres-svc 5432:5432

# Run your app
python -m app.main
```

### End of Day

```bash
cd scripts/infrastructure
./cleanup.sh
# Type: yes
```

### Check Cluster Status

```bash
# View all resources
kubectl get all --all-namespaces

# View apps
kubectl get pods,svc,ingress -n exercises

# View database
kubectl get pods,svc -n database

# View logs
kubectl logs -n exercises -l app=pingpong --tail=50 -f
```

## 💡 Tips & Tricks

### Making Scripts Executable

```bash
chmod +x scripts/**/*.sh
```

### Quick Access with Aliases

Add to your `~/.zshrc`:

```bash
alias kinfra='cd ~/code-projects/patrikwm/public/KubernetesSubmissions/scripts/infrastructure'
alias kapps='cd ~/code-projects/patrikwm/public/KubernetesSubmissions/scripts/apps'
alias kdev='cd ~/code-projects/patrikwm/public/KubernetesSubmissions/scripts/dev'
```

### Check Ingress IP

```bash
kubectl get ingress -n exercises -o wide
```

### Watch Pod Status

```bash
kubectl get pods -n exercises --watch
```

### View Application Logs

```bash
# Ping-pong
kubectl logs -n exercises -l app=pingpong -f

# Postgres
kubectl logs -n database -l app=postgres -f
```

### Connect to Postgres CLI

```bash
# Port forward first
cd scripts/dev
./port-forward.sh database postgres-svc 5432:5432

# In another terminal
psql -h localhost -p 5432 -U postgres -d postgres
```

## 🚨 Troubleshooting

### Ingress Not Getting IP

**Problem:** Ingress shows no ADDRESS after deployment.

**Solution:**
```bash
# Check if app-routing is enabled
kubectl get pods -n app-routing-system

# If not, enable it
cd scripts/infrastructure
./01-enable-ingress.sh
```

### Pods Stuck in Pending

**Problem:** Pods won't schedule.

**Solution:**
```bash
# Check node status
kubectl get nodes

# Describe pod to see events
kubectl describe pod <pod-name> -n <namespace>

# Common issue: insufficient resources
# Solution: Scale down replicas or increase node count
```

### Cannot Connect to Postgres

**Problem:** App can't connect to database.

**Solution:**
```bash
# Check if postgres is running
kubectl get pods -n database

# Check service
kubectl get svc -n database

# Verify connection from app pod
kubectl exec -it <app-pod> -n exercises -- sh
ping postgres-svc.database
```

### ALB Controller Issues

**Problem:** ALB not working in Sweden Central.

**Solution:** Use NGINX ingress instead (01-enable-ingress.sh).
ALB is only available in: northeurope, westeurope, eastus, etc.

## 📝 Configuration

### Changing Cluster Size

Edit `scripts/infrastructure/config.sh` or modify `00-create-cluster.sh`:

```bash
--node-count 3              # Change from 5 to 3
--node-vm-size Standard_B2s # Change VM size
```

### Changing Region

⚠️ **Warning:** Some features have region limitations.

Edit `scripts/infrastructure/config.sh`:

```bash
export LOCATION="northeurope"  # Change from swedencentral
```

### Adding New Applications

1. Create new script: `scripts/apps/deploy-myapp.sh`
2. Follow the pattern from existing scripts
3. Make it executable: `chmod +x scripts/apps/deploy-myapp.sh`

## 🎓 Learning Resources

- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [DevOps with Kubernetes MOOC](https://courses.mooc.fi/org/uh-cs/courses/devops-with-kubernetes/)

## 💰 Cost Management

**Estimated costs** with current configuration:
- ~$159/month for 5 x Standard_B2s nodes
- Free tier Kubernetes control plane

**To minimize costs:**
1. Delete cluster daily with `cleanup.sh`
2. Reduce node count to 3
3. Use spot instances (requires cluster recreation)

**Check current costs:**
```bash
az consumption usage list --start-date 2025-10-01 --end-date 2025-10-31
```

---

**Created for:** DevOps with Kubernetes course lab work
**Maintained by:** @patrikwm
