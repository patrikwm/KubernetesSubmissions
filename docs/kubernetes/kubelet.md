⚙️ Kubernetes Kubelet

The kubelet is the agent that runs on every node.
Its primary job is to ensure that containers are running exactly as declared in the cluster’s desired state.

It’s the direct executor between the control plane and the container runtime — the bridge from API instructions to actual processes on the node.

⸻

🧭 High-Level Role

Type | Description
Control | Watches the API Server for Pod assignments (spec.nodeName=this-node)
Execution | Starts, stops, and monitors containers through the Container Runtime Interface (CRI)
Reporting | Continuously updates Pod status, Node conditions, and metrics to the API Server


⸻

🔗 Who the Kubelet Talks To

| Peer | Purpose | Direction |
|------|---------|-----------|
| API Server | Retrieve assigned Pods, Secrets, ConfigMaps, ServiceAccounts; send Pod/Node status | 🔄 Two-way |
| Container Runtime (containerd, CRI-O) | Start/stop containers, pull images | ⬇️ Downstream (local socket) |
| CNI Plugin | Create Pod network namespaces and assign IP addresses | ⬇️ Downstream (local binary call) |
| kube-proxy | ❌ No direct communication — both independently watch the API Server |
| Local cAdvisor (built-in) | Collect metrics | internal |

✅ The kubelet never talks directly to etcd, the scheduler, or kube-proxy.
All coordination happens through the API Server.

⸻

🧩 Kubelet Pod Lifecycle Flow

```bash
┌──────────────────────────────────────────────────────────┐
│                   API SERVER                             │
│  (holds desired state, incl. pods assigned to node)      │
└───────────────▲──────────────────────────────────────────┘
                │  watch (Pods assigned to nodeName=this-node)
                ▼
┌───────────────────────────────────────────────────────────────────┐
│                       KUBELET                                     │
│                                                                   │
│  1. Watches API server for new/changed Pods                       │
│  2. For each Pod:                                                 │
│     ├─ Pull Secrets & ConfigMaps                                   │
│     ├─ Create Pod sandbox                                         │
│     ├─ Call CNI plugin → set up network, IP address               │
│     ├─ Start container(s) via CRI                                 │
│     ├─ Inject env vars and mount secrets/configs                   │
│     ├─ Monitor container health & probes                          │
│     ├─ Update Pod.status back to API Server                       │
│     └─ Emit events (“Started container”, “Liveness probe failed”) │
│                                                                   │
│  3. Periodically:                                                 │
│     ├─ Update Node.status (Ready, DiskPressure, etc.)             │
│     ├─ Send heartbeats (Node leases)                              │
│     └─ Report metrics via /stats/summary (for metrics-server)     │
└───────────────────────────────────────────────────────────────────┘
```

⸻

🧠 Internal Workflow (Detailed)

1️⃣ Watch for Pod Assignments

The kubelet maintains a watch on:

/api/v1/pods?fieldSelector=spec.nodeName=<this-node>

As soon as the scheduler assigns a Pod to this node, the kubelet gets an event.

⸻

2️⃣ Sync Loop

The kubelet runs a continuous Pod sync loop every few seconds:

for pod in assignedPods:
    desired = pod.spec
    actual = runtimeState(pod)
    if desired != actual:
        reconcilePod(pod)

If a container isn’t running or doesn’t match the spec, it fixes it.

⸻

3️⃣ Pod Creation Sequence
 | 1. | Fetch required data
 | • | Secrets, ConfigMaps, and ServiceAccount tokens via the API Server.
 | • | ImagePullSecrets for registries.
 | 2. | Create the Pod sandbox
 | • | Ask container runtime to create network namespace and container sandbox.
 | 3. | Call CNI plugin
 | • | /opt/cni/bin/<plugin> assigns IP and connects Pod to network.
 | 4. | Mount volumes and inject secrets/configs
 | • | Kubelet writes Secret/ConfigMap contents to /var/lib/kubelet/pods/<uid>/volumes/...
 | • | Mounts those into the container filesystem.
 | 5. | Inject environment variables
 | • | Passes them to container runtime before start.
 | 6. | Pull image (if not cached).
 | 7. | Start container(s).
 | 8. | Run probes (liveness, readiness, startup).

⸻

4️⃣ Reporting Status

After startup:
 | • | Reports container statuses:

status:
  phase: Running
  containerStatuses:
  - name: app
    ready: true
    restartCount: 0


 | • | Sends these via:

PUT /api/v1/namespaces/default/pods/<pod-name>/status


 | • | Updates Node status (CPU, mem, disk, conditions) periodically:

PUT /api/v1/nodes/<node-name>/status


 | • | If kubelet crashes or loses connectivity, the Node Controller in the control plane will mark it NotReady.

⸻

5️⃣ Health & Evictions

If the node is under pressure:
 | • | Eviction Manager triggers pod termination based on resource usage.
 | • | Updates NodeCondition (MemoryPressure, DiskPressure, etc.).
 | • | Reports these back via the API server.

⸻

6️⃣ Metrics and Monitoring

Kubelet integrates cAdvisor to collect:
 | • | CPU, memory, filesystem, and network stats for each container.
 | • | Exposes metrics via:
 | • | /metrics
 | • | /metrics/cadvisor
 | • | /stats/summary

These are scraped by metrics-server or Prometheus for:
 | • | Horizontal Pod Autoscaler (HPA)
 | • | Cluster dashboards

⸻

🔐 How kubelet Handles Secrets and Variables

Type | Source | Mount/Injection
Env vars | Pod spec → Secret/ConfigMap | Injected before container start (static)
Mounted Secrets/ConfigMaps | API Server | Mounted as files, updated live
Service Account Token | API Server → Token Controller | Mounted in /var/run/secrets/kubernetes.io/serviceaccount/

The kubelet retrieves these objects via the API server (using its node credentials), writes them locally, and mounts them before the container starts.

⸻

🔄 Heartbeats & Node Lifecycle

Every ~10s–40s, the kubelet:
 | • | Updates its Node lease in the kube-node-lease namespace.
 | • | Updates Node.status (Ready, Allocatable, Capacity).
If heartbeats stop, the Node Controller marks the node as NotReady and starts rescheduling Pods elsewhere.

⸻

🧩 Communication Overview

         ┌──────────────────────────┐
         │      API SERVER          │
         └──────────▲───────────────┘
                    │ watch / update
                    ▼
         ┌──────────────────────────┐
         │        KUBELET           │
         │  - Watches for Pods      │
         │  - Mounts Secrets/Configs│
         │  - Starts containers     │
         │  - Reports status        │
         └──────────┬───────────────┘
                    │ CRI
                    ▼
           ┌────────────────┐
           │ ContainerRuntime│
           │ (containerd)    │
           └────────────────┘
                    │ CNI
                    ▼
           ┌────────────────┐
           │   CNI Plugin   │
           └────────────────┘

🧩 Note: kube-proxy is independent — it also watches the API Server (for Services/Endpoints) but does not receive direct messages from kubelet.

⸻

✅ TL;DR Summary

Role | Description
Watch | Listens to the API Server for Pods assigned to its node
Execute | Pulls images, mounts secrets, starts containers via runtime
Report | Sends Pod and Node status, metrics, and events back to API Server
Communicate with | Only the API Server directly; local runtime & CNI through system interfaces
Does NOT talk to | etcd, scheduler, controller-manager, kube-proxy


⸻

🧩 Analogy

API Server: The project manager assigning tasks.
Scheduler: The dispatcher deciding who gets the task.
Kubelet: The worker who actually does the job, reports progress, and says “done.”

