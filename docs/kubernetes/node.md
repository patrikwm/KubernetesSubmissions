🖥️ Kubernetes Node

A Node is a worker machine in Kubernetes — either a VM or physical host — that runs Pods and reports status to the control plane.

Each node hosts several components that perform the actual work:

- kubelet — the node agent that runs and monitors containers.
- kube-proxy — handles networking for Services and Pods.
- container runtime — runs the containers (containerd, CRI-O, etc.).
- CNI plugin — configures Pod networking and IPs.

⸻

⚙️ Node Overview

```bash
┌─────────────────────────────┐
│         Control Plane       │
│  (API Server, etcd, etc.)   │
└──────────▲───────┬──────────┘
           │       │
 (watch)   │       │ (status updates)
           ▼       ▼
 ┌─────────────────────────────┐
 │            Node             │
 │ ┌─────────────────────────┐ │
 │ │        kubelet          │ │
 │ │ - Watches for Pods      │ │
 │ │ - Runs containers       │ │
 │ │ - Reports status        │ │
 │ └─────────────────────────┘ │
 │ ┌─────────────────────────┐ │
 │ │       kube-proxy        │ │
 │ │ - Manages network rules │ │
 │ └─────────────────────────┘ │
 │ ┌─────────────────────────┐ │
 │ │   Container Runtime     │ │
 │ │ - Pulls images          │ │
 │ │ - Runs containers       │ │
 │ └─────────────────────────┘ │
 │ ┌─────────────────────────┐ │
 │ │       CNI Plugin        │ │
 │ │ - Configures networking  │ │
 │ └─────────────────────────┘ │
 └─────────────────────────────┘
```

⸻

🧠 kubelet — the Node Agent

The kubelet is the “foreman” of the node. It:
1. Watches the API server for Pods assigned to this node.
2. Creates containers via the container runtime.
3. Monitors Pod and node health.
4. Reports Pod and node status back to the API server.

**Simplified loop**

```python
while true:
    pods = watch(API server for pods assigned to me)
    for pod in pods:
        if not running:
            create sandbox, mount secrets, start containers
        report status back to API server
```

⸻

🧱 kube-proxy — the Network Traffic Cop

- Watches the API server for Services and Endpoints.
- Updates the local node’s iptables or IPVS rules to route Service traffic to backend Pods.
- Provides in-cluster load balancing and ClusterIP behavior.

⸻

🧰 Container Runtime — the Worker

The container runtime is what actually runs containers.
Common runtimes:

- containerd (default on most clusters)
- CRI-O
- Docker (legacy via dockershim)

The kubelet communicates with the runtime using the Container Runtime Interface (CRI):

`/var/run/containerd/containerd.sock` (for containerd)

Runtime responsibilities:

- Pull images from registries.
- Create namespaces, cgroups, and sandboxes.
- Run and stop containers.
- Report container-level metrics (CPU, memory, IO).

⸻

📦 CNI Plugin — Pod Networking

The Container Network Interface (CNI) plugin assigns each Pod its IP address and sets up the virtual interfaces (veth pairs, bridges, routes).
Examples:

- Calico
- Flannel
- Cilium
- Weave Net

When kubelet creates a Pod sandbox, it calls the plugin through:

`/opt/cni/bin/<plugin-name>`

and the plugin returns:

```json
{ "ip4": { "ip": "10.244.0.15/24" } }
```

⸻

🔐 Secrets, ConfigMaps, and Environment Variables

When you reference a Secret, ConfigMap, or env variable in your Pod spec, the kubelet is responsible for injecting them into the container before it starts.

1️⃣ Environment Variables

Defined like:

```yaml
env:
- name: APP_MODE
  value: "production"
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: my-secret
      key: api-key
```

Process:

1. The kubelet fetches the referenced Secret/ConfigMap from the API server.
2. It passes these values to the container runtime as environment variables when starting the container process.
3. Inside the container, they appear as normal environment vars:

```bash
echo $APP_MODE
echo $SECRET_KEY
```


⸻

2️⃣ Mounted Volumes (Secrets / ConfigMaps)

Defined like:

```yaml
volumes:
- name: app-secrets
  secret:
    secretName: my-secret
```


Process:

1. Kubelet retrieves the Secret from the API server.
2. It writes it as files under:

```bash
/var/lib/kubelet/pods/<pod-uid>/volumes/kubernetes.io~secret/app-secrets/
```

3. It mounts that directory into the container:

```bash
/etc/secrets/<key-name>
```

4. Any updates to the Secret are automatically reflected inside the Pod within a few seconds.

⸻

3️⃣ Service Account Tokens

Each Pod gets a projected volume called:

```bash
/var/run/secrets/kubernetes.io/serviceaccount/
```

containing:

- token (JWT for authentication to API server)
- ca.crt (cluster CA)
- namespace (namespace name)

The kubelet mounts this automatically (unless automountServiceAccountToken: false).

⸻

🔁 Update flow for secrets & env

- Mounted Secrets/ConfigMaps: kubelet watches for changes and updates the mounted files automatically.
- Environment variables: not updated after container start — these are static.

⸻

📊 Node Reporting & Health

The kubelet continuously reports:
- Node capacity and allocatable resources.
- Conditions (Ready, DiskPressure, MemoryPressure, etc.).
- Running Pod statuses.
- Container restarts and failures.

Reported through:

```bash
PUT /api/v1/nodes/<node-name>/status
PUT /api/v1/namespaces/default/pods/<pod-name>/status
```

You can see this in real time:

```bash
kubectl describe node <node-name>
kubectl get nodes -o wide
```

⸻

🧮 Metrics and cAdvisor

Each kubelet includes cAdvisor (Container Advisor) to gather per-container metrics (CPU, memory, filesystem, network).
The data is exposed on the kubelet’s local endpoints:

| Endpoint | Description |
|----------|-------------|
| /metrics | kubelet metrics |
| /metrics/cadvisor | container-level metrics |
| /stats/summary | summarized metrics for metrics-server |

The metrics-server scrapes /stats/summary for cluster-level monitoring and autoscaling (HPA).

⸻

🧭 Node Lifecycle
1. Registration:
    Kubelet registers itself with the API server (/api/v1/nodes).
2. Heartbeat:
    Sends updates every 10s–40s to keep Node Ready.
3. Status updates:
    Reports node and pod statuses regularly.
4. Eviction:
    If the node stops responding, the Node Controller marks it NotReady and starts evicting pods.

⸻

🧩 Node Component Interaction Flow

```bash
┌────────────────────────────────────────────────┐
│              API Server (control plane)        │
└────────────────────────────────────────────────┘
                 ▲            ▲
 (watches Pods)  │            │  (status updates)
                 │            │
                 │            │
     ┌───────────┴────────────┴───────────┐
     │               KUBELET              │
     │  - Watches for Pods                │
     │  - Retrieves Secrets/ConfigMaps     │
     │  - Creates containers via CRI      │
     │  - Reports Pod/Node status         │
     └───────────┬────────────┬───────────┘
                 │            │
                 ▼            ▼
        ┌───────────────┐   ┌───────────────┐
        │ Container     │   │   kube-proxy  │
        │ Runtime (CRI) │   │  - Watches API│
        │ - Runs images │   │  - Sets routes│
        └───────────────┘   └───────────────┘
                 │
                 ▼
          ┌─────────────┐
          │ CNI Plugin  │
          │ - Assign IP │
          │ - Setup net │
          └─────────────┘
```

⸻

🧭 TL;DR Summary

Component | Purpose | Talks to
kubelet | Node agent that runs and monitors Pods, mounts secrets, injects env vars | API server, container runtime
container runtime | Runs containers and pulls images | kubelet
kube-proxy | Handles Service networking | API server
CNI plugin | Configures Pod networking | kubelet
cAdvisor (in kubelet) | Collects container metrics | metrics-server, kubelet


⸻

🔍 Useful Commands

# List all nodes and their status
kubectl get nodes

# Show node capacity and conditions
kubectl describe node <node-name>

# View running Pods on this node
kubectl get pods -o wide --all-namespaces | grep <node-name>

# SSH into a node (minikube example)
minikube ssh

# Check kubelet logs
sudo journalctl -u kubelet -f


⸻

✅ In short:

A Node is the execution layer of Kubernetes.
The kubelet listens for assignments, runs containers through the runtime, mounts secrets and configuration, and reports continuous health and metrics to the API server.

