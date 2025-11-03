# Kubernetes Components

A comprehensive guide to understanding all the components that make up a Kubernetes cluster, from core infrastructure to optional add-ons and cloud-specific integrations.

---

## Overview

Kubernetes is composed of multiple layers:

- **Core Components** - The essential components required for a functioning cluster
- **Standard Add-ons** - Commonly installed components that extend baseline functionality
- **Optional Add-ons** - Additional components for monitoring, security, networking, and more
- **Cloud-Specific Components** - Provider-specific integrations and controllers
- **Tools** - CLIs, dashboards, and package managers for working with Kubernetes

---

## 1. Core Components (Required)

These are the minimum components needed for a functioning Kubernetes cluster. Without these, Kubernetes cannot create or manage Pods.

### Control Plane Components

The control plane makes global decisions about the cluster and detects/responds to cluster events.

#### kube-apiserver
- Central REST API endpoint for all cluster operations
- Every command (kubectl, controllers, kubelet) communicates through here
- The only component that directly talks to etcd
- Serves as the front-end for the Kubernetes control plane
- Validates and processes REST operations

#### etcd
- Distributed key-value store for all cluster state
- Stores what exists and what should exist in the cluster
- Highly available and consistent datastore
- Only accessible through the API server
- All cluster data is stored here (configuration, state, metadata)

#### kube-scheduler
- Assigns Pods to specific nodes based on available resources and constraints
- Makes decisions based on:
  - Resource requirements and availability
  - Taints and tolerations
  - Node affinity and anti-affinity rules
  - Custom constraints and policies
- See [Kubernetes Scheduler](./scheduler.md) for detailed information

#### kube-controller-manager
- Runs built-in controllers that reconcile cluster state
- Manages core controllers including:
  - **Node Controller** - Monitors node health
  - **ReplicaSet Controller** - Maintains desired replica count
  - **Deployment Controller** - Manages Deployments
  - **Endpoints Controller** - Populates Endpoints objects
  - **ServiceAccount Controller** - Creates default ServiceAccounts
  - **Namespace Controller** - Manages namespace lifecycle

#### cloud-controller-manager
- Only needed when using a cloud provider (AWS, GCP, Azure, etc.)
- Integrates with cloud provider APIs for:
  - Load balancers
  - Persistent volumes
  - Node lifecycle management
  - Route management

### Node Components

These components run on every node in the cluster and maintain running pods.

#### kubelet
- Primary node agent that runs on each node
- Watches the API server for Pods assigned to its node
- Ensures containers are running as declared in PodSpecs
- Reports node and pod status back to the control plane
- Manages container lifecycle through the container runtime
- Does not manage containers not created by Kubernetes

#### kube-proxy
- Network proxy that runs on each node
- Maintains network rules (iptables/ipvs) for Service networking
- Handles load balancing for Services within the cluster
- Enables communication to Pods from inside or outside the cluster
- Implements the Service abstraction

#### Container Runtime
- Low-level component responsible for running containers
- Common runtimes:
  - **containerd** (most common, default in many distros)
  - **CRI-O** (lightweight, OCI-compliant)
  - **Docker** (deprecated, removed in Kubernetes 1.24+)
- Must implement the Kubernetes CRI (Container Runtime Interface)

> **Note:** Without these core components, Kubernetes cannot function.

---

## 2. Standard Add-ons (Commonly Installed)

These components are typically installed by kubeadm, Minikube, or managed clusters. While not strictly required for cluster boot, you'll rarely run without them.

### CoreDNS
- **Namespace:** `kube-system`
- Provides internal DNS resolution for Services and Pods
- Enables service discovery within the cluster
- Replaces kube-dns in modern clusters
- Configurable via ConfigMap

### metrics-server
- **Namespace:** `kube-system`
- Aggregates CPU and memory metrics from kubelets
- Powers `kubectl top` commands
- Required for Horizontal Pod Autoscalers (HPA)
- Collects resource metrics from Kubelet API

### Storage Provisioner / CSI Drivers
- **Namespace:** `kube-system`
- Dynamically creates PersistentVolumes
- Implements Container Storage Interface (CSI)
- Different implementations for different environments:
  - Cloud providers (AWS EBS, GCP PD, Azure Disk)
  - Minikube storage provisioner
  - Local path provisioner
  - NFS, Ceph, GlusterFS provisioners

### ServiceAccount Controllers
- **Namespace:** `kube-system`
- Manages API tokens for Pods
- Creates default ServiceAccounts in namespaces
- Handles token rotation and lifecycle

---

## 3. Optional Add-ons (Enhancements)

These components are not required but are commonly added to production clusters to extend functionality.

### Observability

#### kube-state-metrics
- Exposes Kubernetes object metrics to Prometheus
- Provides insights into cluster resource states
- Monitors Deployments, Pods, Nodes, etc.
- Generates metrics about the state of objects

#### Prometheus & Grafana
- **Prometheus:** Time-series database and monitoring system
- **Grafana:** Visualization and dashboarding platform
- Together provide comprehensive metrics and alerting
- Industry standard for Kubernetes monitoring

#### Logging Stack
- **Loki:** Log aggregation system (Prometheus for logs)
- **Fluentd:** Log collector and processor
- **EFK Stack:** Elasticsearch, Fluentd, Kibana
- Centralized log collection and analysis

#### Distributed Tracing
- **Jaeger:** End-to-end distributed tracing
- **OpenTelemetry:** Observability framework
- **Zipkin:** Distributed tracing system
- Tracks requests across microservices

### Networking & Ingress

#### CNI Plugin (Container Network Interface)
Required for Pod-to-Pod networking. Popular options:
- **Calico** - Network policy and security
- **Flannel** - Simple overlay network
- **Cilium** - eBPF-based networking
- **Weave Net** - Easy setup and encryption
- **Antrea** - Kubernetes-native networking

#### Ingress Controller
Exposes HTTP(S) services to external traffic:
- **NGINX Ingress Controller** (most popular)
- **Traefik** - Modern HTTP reverse proxy
- **HAProxy** - High-performance load balancer
- **Kong** - API gateway and ingress
- **Contour** - Envoy-based ingress

#### MetalLB
- Load balancer for bare-metal Kubernetes
- Provides LoadBalancer service type without cloud provider
- Uses BGP or Layer 2 modes
- Essential for on-premises clusters

#### External-DNS
- Automatically manages DNS records
- Syncs Services/Ingresses with DNS providers
- Supports Route53, CloudDNS, Azure DNS, and more

### Autoscaling & Scheduling

#### Cluster Autoscaler
- Automatically adjusts the number of nodes
- Scales node pools up when Pods can't be scheduled
- Scales down when nodes are underutilized
- Cloud provider specific

#### Horizontal Pod Autoscaler (HPA)
- Scales the number of Pods based on metrics
- Uses CPU, memory, or custom metrics
- Built-in controller, requires metrics-server
- Automatically adjusts replica count

#### Vertical Pod Autoscaler (VPA)
- Adjusts Pod resource requests and limits
- Recommends optimal resource allocations
- Can automatically apply recommendations
- Helps optimize resource usage

#### Descheduler
- Rebalances Pods across nodes
- Evicts Pods for better cluster utilization
- Runs as a job or CronJob
- Improves cluster efficiency over time

### Security & Policy

#### Network Policies
- Controls Pod-to-Pod traffic
- Implemented by CNI plugin (not all support it)
- Defines ingress and egress rules
- Essential for zero-trust networking

#### RBAC (Role-Based Access Control)
- Enabled by default in modern clusters
- Controls who can access what resources
- Uses Roles, ClusterRoles, and Bindings
- Fine-grained permission management

#### Policy Engines
- **OPA/Gatekeeper** - General-purpose policy engine
- **Kyverno** - Kubernetes-native policy management
- Enforce security policies, best practices, compliance
- Validate, mutate, and generate resources

#### cert-manager
- Automates TLS certificate management
- Integrates with Let's Encrypt (ACME)
- Supports internal CAs and custom issuers
- Automatic certificate renewal

#### Falco
- Runtime security monitoring
- Detects anomalous behavior in containers
- Uses eBPF or kernel modules
- Provides security alerts

### Service Mesh & Advanced Networking

#### Service Mesh Options
- **Istio** - Feature-rich service mesh
- **Linkerd** - Lightweight and fast
- **Consul** - HashiCorp's service mesh
- **Kuma** - Universal control plane

**Features provided:**
- mTLS between services
- Advanced traffic control (canary, blue-green)
- Observability and telemetry
- Circuit breaking and retries
- Fault injection

---

## 4. Cloud-Specific Components

These components integrate Kubernetes with cloud provider services and features.

### AWS Components

#### AWS Load Balancer Controller
- Manages AWS Elastic Load Balancers (ALB/NLB)
- Replaces the legacy in-tree cloud provider
- **Installation:**
  1. Install CRDs: `kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"`
  2. Install via Helm: `helm install aws-load-balancer-controller eks/aws-load-balancer-controller`
- Enables Ingress and Service type LoadBalancer with AWS features
- Supports target group binding and IP mode

#### AWS EBS CSI Driver
- Container Storage Interface driver for AWS EBS volumes
- Enables dynamic provisioning of EBS volumes
- Required for EKS 1.23+ (in-tree driver deprecated)

#### AWS EFS CSI Driver
- Provides shared file system storage
- Enables ReadWriteMany access mode
- Ideal for shared data across pods

#### AWS VPC CNI
- Default CNI for EKS clusters
- Assigns VPC IP addresses to pods
- Enables native VPC networking

### Azure Components

#### Azure Application Gateway Ingress Controller (AGIC)
- Integrates AKS with Azure Application Gateway
- Provides Layer 7 load balancing
- **Installation:**
  1. Install CRDs and controller via Helm
  2. Configure Application Gateway resource
- Supports SSL termination, URL routing, WAF

#### Azure Disk CSI Driver
- Provides block storage for AKS
- Supports multiple disk types (Standard, Premium, Ultra)
- Dynamic provisioning of Azure Disks

#### Azure File CSI Driver
- Provides shared file storage via Azure Files
- Supports SMB and NFS protocols
- ReadWriteMany access mode

#### Azure CNI
- Default networking for AKS
- Assigns Azure VNet IPs to pods
- Integrates with Azure networking features

#### Azure Key Vault Provider for Secrets Store CSI Driver
- Integrates AKS with Azure Key Vault
- Mounts secrets, keys, and certificates as volumes
- Supports pod identity and managed identity

### GCP Components

#### GKE Ingress Controller
- Manages Google Cloud Load Balancers
- Integrated with GKE by default
- Supports URL maps and SSL certificates

#### GCP Compute Persistent Disk CSI Driver
- Provides block storage for GKE
- Dynamic provisioning of persistent disks
- Supports regional persistent disks

#### GKE Autopilot Components
- Managed node pools
- Automatic scaling and upgrades
- Pre-configured security policies

### Gateway API (Cross-Cloud)

#### Gateway API Controllers
- Next-generation Ingress API
- More expressive and extensible than Ingress
- Supported by multiple implementations:
  - **Istio Gateway**
  - **Contour Gateway**
  - **AWS Load Balancer Controller** (GatewayClass: `amazon-vpc-lattice`)
  - **Azure Application Gateway**
  - **Google Cloud Load Balancer**

**Example GatewayClass usage (AWS):**
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: amazon-vpc-lattice
spec:
  controllerName: application-networking.k8s.aws/gateway-api-controller
```

---

## 5. Tools

Essential tools for working with Kubernetes clusters.

### CLI Tools

#### kubectl
- Official Kubernetes command-line tool
- Primary interface for cluster interaction
- Supports plugins via krew
- See [kubectl and Pod Management](./kubectl-pod.md) and [kubectl and Deployment Management](./kubectl-deployment.md)

#### kubectx / kubens
- Switch between clusters and namespaces quickly
- Simplifies multi-cluster management
- Popular community tool

#### krew
- Plugin manager for kubectl
- Discover and install kubectl plugins
- Over 200 plugins available

#### stern
- Multi-pod and container log tailing
- Powerful filtering and coloring
- Better than `kubectl logs` for multiple pods

#### k9s
- Terminal-based UI for Kubernetes
- Real-time cluster monitoring
- Interactive resource management
- Highly efficient for day-to-day operations

#### kubectlAlias / k
- Short aliases for kubectl commands
- Speed up common operations
- Customizable shortcuts

### Package Managers

#### Helm
- Package manager for Kubernetes
- Uses "Charts" to define applications
- Template-based configuration
- De facto standard for application distribution
- Version 3+ (no Tiller required)

#### Kustomize
- Template-free configuration management
- Patch-based approach
- Native kubectl integration (`kubectl apply -k`)
- GitOps-friendly

#### Carvel (ytt, kapp, imgpkg)
- Suite of tools for application management
- ytt: YAML templating
- kapp: Application deployment
- imgpkg: Image bundling

### UI & Desktop Tools

#### Kubernetes Dashboard
- Official web UI for cluster management
- View and modify cluster resources
- Visualize cluster state
- Good for beginners

#### Lens
- Desktop IDE for Kubernetes
- Multi-cluster management
- Built-in terminal and metrics
- Extensions ecosystem

#### K9s
- Terminal-based UI (already mentioned above)
- Efficient keyboard navigation
- Real-time cluster monitoring

#### Octant
- Developer-centric web UI
- Plugin-based architecture
- Local dashboard without cluster installation

#### Portainer
- Web-based management UI
- Supports multiple orchestrators
- User-friendly interface

### CI/CD & GitOps Tools

#### Argo CD
- Declarative GitOps continuous delivery
- Monitors Git repos and syncs to clusters
- Web UI for application management
- Multi-cluster support

#### Flux
- GitOps toolkit for Kubernetes
- Automated deployments from Git
- Helm and Kustomize support
- CNCF graduated project

#### Tekton
- Cloud-native CI/CD framework
- Kubernetes-native pipelines
- Reusable pipeline components

#### Jenkins X
- CI/CD solution for Kubernetes
- Automated pipeline creation
- Built-in GitOps

### Development Tools

#### Skaffold
- Automates build, push, and deploy workflow
- Hot reload for development
- Multiple deployment strategies
- Integrates with Helm, kubectl, Kustomize

#### Tilt
- Local development for microservices
- Fast feedback loop
- Live updates to running containers
- Easy multi-service development

#### DevSpace
- Developer tool for Kubernetes
- Hot reloading and debugging
- Simplified development workflows

#### Draft
- Streamlines app development on Kubernetes
- Generates Dockerfiles and Helm charts
- Simplifies onboarding

### Debugging & Troubleshooting Tools

#### kubeshark
- API traffic viewer for Kubernetes
- Wireshark-like experience
- Real-time traffic monitoring

#### kubectl-debug
- Add debugging container to running pods
- Troubleshoot containers without modifying them
- Essential for debugging distroless images

#### Goldpinger
- Visualizes cluster networking
- Detects connectivity issues
- Shows cluster topology

### Security Scanning Tools

#### Trivy
- Vulnerability scanner for containers
- Scans images, filesystems, and Git repos
- Detects misconfigurations

#### Kubesec
- Security risk analysis for Kubernetes resources
- Scores manifests for security
- Suggests improvements

#### kube-bench
- Checks cluster against CIS Kubernetes Benchmark
- Identifies security misconfigurations
- Automated security auditing

---

## Component Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Control Plane                            │
│                                                              │
│  ┌──────────┐    ┌──────┐    ┌───────────┐    ┌──────────┐ │
│  │   API    │◄──►│ etcd │    │ Scheduler │    │Controller│ │
│  │  Server  │    └──────┘    └─────┬─────┘    │ Manager  │ │
│  └────┬─────┘                      │           └────┬─────┘ │
│       │                            │                │       │
└───────┼────────────────────────────┼────────────────┼───────┘
        │                            │                │
        │ (watch)             (bind) │                │ (watch)
        ▼                            ▼                ▼
┌──────────────────────────────────────────────────────────────┐
│                         Worker Nodes                          │
│                                                              │
│  ┌─────────┐         ┌─────────┐         ┌─────────┐       │
│  │ kubelet │◄───────►│  Pods   │         │  kube-  │       │
│  └────┬────┘         └────┬────┘         │  proxy  │       │
│       │                   │              └────┬────┘       │
│       │ (CRI)             │                   │ (iptables) │
│       ▼                   │                   ▼            │
│  ┌──────────────────┐    │              ┌─────────────┐  │
│  │ Container Runtime│◄───┘              │  Services   │  │
│  │  (containerd)    │                   │  Networking │  │
│  └──────────────────┘                   └─────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## Summary Table

| Category | Examples | Mandatory? |
|----------|----------|------------|
| **Core Components** | API Server, etcd, Scheduler, Controller Manager, Kubelet, kube-proxy, Container Runtime | ✅ Yes |
| **Standard Add-ons** | CoreDNS, metrics-server, Storage Provisioner, Cloud Controller | ⚙️ Usually |
| **Optional Add-ons** | Prometheus, Ingress Controller, CNI plugin, Dashboard, cert-manager, HPA, VPA | 🔌 Optional |
| **Cloud Components** | AWS LB Controller, Azure AGIC, GKE Ingress, CSI Drivers | ☁️ Cloud-specific |
| **Tools** | kubectl, Helm, k9s, Lens, Argo CD, Skaffold | 🛠️ For management |

---

## Next Steps

To deepen your understanding:

1. **Experiment** - Deploy each component type in a test cluster
2. **Monitor** - Watch component logs to see interactions
3. **Break Things** - See what happens when components fail
4. **Build** - Create a cluster from scratch with kubeadm
5. **Explore Cloud Integration** - Try cloud-specific controllers in your managed cluster

For more detailed information, see:
- [Kubernetes Scheduler](./scheduler.md)
- [kubectl and Pod Management](./kubectl-pod.md)
- [kubectl and Deployment Management](./kubectl-deployment.md)
