# Quick Reference Card 🚀

## 📋 Daily Lab Workflow

### Morning Setup (5-10 min)
```bash
cd scripts/infrastructure
./00-create-cluster.sh    # Create cluster
./01-enable-ingress.sh    # Enable ingress
```

### Deploy Apps (2-3 min each)
```bash
cd ../apps
./deploy-postgres.sh      # Deploy database first
./deploy-ping-pong.sh     # Deploy app
```

### Get App URL
```bash
kubectl get ingress -n exercises -o wide
# Copy the ADDRESS column
```

### Evening Cleanup (< 1 min)
```bash
cd ../infrastructure
./cleanup.sh              # Delete everything
# Type: yes
```

## 🔧 Quick Commands

### Infrastructure
| Command | Description |
|---------|-------------|
| `./00-create-cluster.sh` | Create AKS cluster |
| `./01-enable-ingress.sh` | Enable NGINX ingress |
| `./02-enable-alb.sh` | Enable ALB (not in swedencentral) |
| `./cleanup.sh` | Delete cluster & resources |

### Applications
| Command | Description |
|---------|-------------|
| `./deploy-postgres.sh` | Deploy PostgreSQL |
| `./deploy-ping-pong.sh` | Deploy ping-pong app |
| `./deploy-log-output.sh` | Deploy log-output app |
| `./deploy-todo-app.sh` | Deploy todo frontend |
| `./deploy-todo-backend.sh` | Deploy todo backend |
| `./deploy-*.sh delete` | Delete the app |

### Development
| Command | Description |
|---------|-------------|
| `./setup-venv.sh` | Setup Python venv |
| `./port-forward.sh <ns> <svc> <port:port>` | Port forward service |
| `./run-tests.sh` | Run all tests |

## 📊 Useful kubectl Commands

```bash
# Get all ingress IPs
kubectl get ingress -A

# Watch pods
kubectl get pods -n exercises --watch

# View logs
kubectl logs -n exercises -l app=pingpong -f

# Describe resource
kubectl describe pod <name> -n <namespace>

# Get into pod shell
kubectl exec -it <pod-name> -n <namespace> -- sh

# Delete namespace (nuclear option)
kubectl delete namespace exercises
```

## 🎯 Testing Applications

### Ping-Pong App
```bash
IP=$(kubectl get ingress -n exercises ping-pong-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$IP/pingpong
curl http://$IP/pings
```

### Log Output
```bash
IP=$(kubectl get ingress -n exercises log-output-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$IP/
```

### Todo App
```bash
IP=$(kubectl get ingress -n exercises todo-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
open http://$IP/
```

## 🐛 Troubleshooting

### Ingress has no IP
```bash
# Enable app routing
./01-enable-ingress.sh
```

### Pod not starting
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Can't connect to postgres
```bash
# Check postgres is running
kubectl get pods -n database

# Port forward and test
cd scripts/dev
./port-forward.sh database postgres-svc 5432:5432
```

### Forgot what's deployed
```bash
kubectl get all -n exercises
kubectl get all -n database
```

## 💡 Pro Tips

1. **Aliases** - Add to ~/.zshrc:
   ```bash
   alias k='kubectl'
   alias kge='kubectl get events --sort-by=.metadata.creationTimestamp'
   alias kgp='kubectl get pods'
   alias kgs='kubectl get svc'
   alias kgi='kubectl get ingress'
   ```

2. **Auto-complete**:
   ```bash
   source <(kubectl completion zsh)
   ```

3. **Contexts**:
   ```bash
   kubectl config get-contexts
   kubectl config use-context dwk-cluster
   ```

4. **Quick namespace switch**:
   ```bash
   kubectl config set-context --current --namespace=exercises
   ```

## 📁 Directory Navigation

```
KubernetesSubmissions/
├── scripts/
│   ├── infrastructure/  ← Cluster management
│   ├── apps/           ← App deployments
│   └── dev/            ← Local development
├── ping-pong_application/
├── postgres/
└── ...
```

## 🎓 Remember

1. **Always start with infrastructure scripts**
2. **Deploy postgres before apps that need it**
3. **Use `delete` argument to remove apps**: `./deploy-postgres.sh delete`
4. **Clean up every day to save costs**: `./cleanup.sh`
5. **Check the full README**: `cat scripts/README.md`

---

**Time estimates:**
- Cluster create: 5-10 min
- App deploy: 1-3 min each
- Cleanup: < 1 min (background)

**Cost per day:** ~$5-10 if deleted daily
