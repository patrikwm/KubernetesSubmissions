# Kubernetes Deployment Flow

When you run `kubectl apply -f deployment.yaml`, Kubernetes translates the manifest into API requests and the control plane works to make the cluster match that desired state. The sequence below highlights the major hops from your terminal to running containers.

## High-Level Sequence

1. `kubectl` loads credentials, validates the manifest, and sends an HTTPS request to the Kubernetes API.
2. The API server authenticates the request, authorizes it, runs admission controllers, and persists the new objects to `etcd`.
3. Control-plane controllers detect the new desired state and begin reconciling it by creating or updating subordinate objects.
4. The scheduler assigns each pending Pod to an appropriate Node.
5. The kubelet on the target node pulls images, mounts configuration, starts containers, and reports status back through the API server.

> kubectl → API Server → etcd → Controllers → Scheduler → Kubelet → API Server

## Component Responsibilities

### kubectl (client)

- Reads cluster context and credentials from `~/.kube/config`.
- Performs basic manifest validation before sending it.
- Issues REST calls (POST, PATCH, DELETE) to the API server and prints the response.

### Kubernetes API Server (front door)

- Authenticates the caller and checks RBAC/ABAC permissions.
- Runs admission controllers (mutating & validating webhooks, defaulting).
- Persists resources in `etcd`, establishing the cluster’s desired state.
- Returns the result (`Created`, `Configured`, `Forbidden`, etc.) to `kubectl`.

### etcd (source of truth)

- Stores every Kubernetes object in a strongly consistent key/value store.
- Enables controllers to compare the desired state (stored in `etcd`) with the observed cluster state.

### Controller Manager (continuous reconciliation)

- Runs control loops that watch the API server and adjust objects until desired state matches reality.

```bash
┌──────────────────────────────┐
│ kube-controller-manager      │
│ ├─ DeploymentController      │
│ ├─ ReplicaSetController      │
│ ├─ StatefulSetController     │
│ ├─ DaemonSetController       │
│ ├─ JobController             │
│ ├─ CronJobController         │
│ ├─ ServiceAccountController  │
│ ├─ NodeController            │
│ ├─ EndpointsController       │
│ ├─ NamespaceController       │
│ ├─ PVController (Volumes)    │
│ ├─ PVCController             │
│ ├─ ServiceController         │
│ ├─ HorizontalPodAutoscaler   │
│ ├─ TTLController             │
│ └─ GarbageCollector          │
└──────────────────────────────┘
```

#### Deployment controller

- Watches for new or updated Deployments.
- Creates or updates ReplicaSets to match `.spec.replicas` and the Pod template.

#### ReplicaSet controller

- Ensures the ReplicaSet has the requested number of Pods.
- Creates or deletes Pods so that the actual count matches the desired count.

### Scheduler

- Watches for Pods without a `spec.nodeName`.
- Scores nodes based on capacity, taints, affinities, and policies.
- Binds each Pod to the chosen node by writing the `nodeName` back to the API server.

### Kubelet (node agent)

- Watches for Pods scheduled to its node.
- Creates the Pod sandbox via the container runtime (CRI).
- Invokes the CNI plugin to obtain networking for each Pod.
- Mounts ConfigMaps and Secrets, pulls images, and starts containers.
- Reports Pod status transitions (Pending → Running → Succeeded/Failed) back to the API server.

### ConfigMaps & Secrets

When referenced by a Deployment (via `env`, `envFrom`, or volumes):

- The kubelet fetches the data from the API server.
- It projects the values into the Pod as environment variables or mounted files.
- Mounted volumes automatically refresh when the ConfigMap or Secret changes.

## Lifecycle of a Deployment

1. **Deployment created** – The Deployment object is stored in `etcd`. No Pods exist yet.
2. **ReplicaSet generated** – The Deployment controller creates (or updates) a ReplicaSet that matches the template.
3. **Pods created** – The ReplicaSet controller notices missing Pods and creates Pod objects.
4. **Pods scheduled** – The scheduler assigns each Pod to a node by setting `spec.nodeName`.
5. **Pods realized** – The kubelet on each selected node pulls images, mounts configuration, and starts containers.
6. **Status reported** – The kubelet reports progress back to the API server, where `kubectl get pods` can observe it.
7. **Ongoing reconciliation** – Scaling, rolling updates, or crashes trigger controllers to repeat the loop until desired = actual.

## Ownership Hierarchy

| Level | Resource   | Managed By             |
|-------|------------|------------------------|
| 1     | Deployment | User (via `kubectl`)   |
| 2     | ReplicaSet | Deployment controller  |
| 3     | Pod        | ReplicaSet controller  |
| 4     | Container  | Kubelet / container runtime |

## Key Takeaways

- Kubernetes reacts to API state: controllers watch `etcd` and continuously reconcile differences.
- The scheduler chooses placement; the kubelet makes that placement real.
- Deployments orchestrate ReplicaSets, and ReplicaSets orchestrate Pods.
- ConfigMaps and Secrets flow through the API server to the kubelet, which injects them into containers.
- `kubectl get` commands reflect the status reported by kubelets through the API server back into `etcd`.



