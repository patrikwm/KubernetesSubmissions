🧠 kube-controller-manager — “the cluster’s autopilot”

The kube-controller-manager (KCM) runs dozens of small controllers, each responsible for keeping a specific part of the cluster in the desired state.

Each controller follows the same loop:

while true:
    actual_state = read_from(API_server)
    desired_state = object.spec
    if actual_state != desired_state:
        take_action()
        update(API_server)
    sleep(short_interval)

That’s the controller pattern — sometimes called a reconciliation loop.

⸻

⚙️ High-level flow

```Bash
┌─────────────────────────────┐
│        API Server           │
│   (desired + actual state)  │
└──────────▲───────┬──────────┘
           │       │
 (watch)   │       │ (update)
           ▼       ▼
   ┌──────────────────────────────┐
   │   kube-controller-manager    │
   │   (many internal controllers)│
   └──────────────────────────────┘
```

Each controller watches specific resource types through the API server and acts to fix drift.

⸻

🧩 Examples of controllers inside the KCM

| Controller | Watches | Ensures |
|------------|---------|---------|
| ReplicationController / ReplicaSet Controller | ReplicaSets | Desired number of Pods running |
| Deployment Controller | Deployments | Creates/updates ReplicaSets for versioned rollouts |
| StatefulSet Controller | StatefulSets | Pods with stable identities and ordering |
| DaemonSet Controller | DaemonSets | One Pod per node |
| Job / CronJob Controller | Jobs/CronJobs | Pod completion and retries |
| Node Controller | Nodes | Marks Nodes as NotReady or Unknown when heartbeats stop |
| Service Controller | Services | Keeps Endpoints/EndpointSlices in sync |
| Namespace Controller | Namespaces | Cleans up resources when a Namespace is deleted |
| ServiceAccount Controller | ServiceAccounts | Creates default ServiceAccount per Namespace |
| Volume / PV Controller | PersistentVolumes, Claims | Attaches/Detaches volumes, manages claims |
| Token Controller | Secrets, ServiceAccounts | Creates tokens for service accounts |
| Garbage Collector | All | Cleans up orphaned objects via ownerReferences |

All these live inside the kube-controller-manager binary — it’s like a “host process” for all these small brains.

⸻

🔄 Example: Deployment → ReplicaSet → Pods

Here’s what happens when you create a Deployment:

kubectl apply -f deployment.yaml

1. API server stores the Deployment object (desired state).
2. Deployment Controller (inside KCM) watches for new/changed Deployments.
3. It sees the Deployment wants, say, replicas: 3.
4. It creates or updates a ReplicaSet object with that desired count.
5. The ReplicaSet Controller watches ReplicaSets → creates Pods until spec.replicas == status.readyReplicas.
6. Scheduler sees unscheduled Pods → assigns them to nodes.
7. Kubelets start the containers → report status back.
8. The controllers reconcile again, ensuring everything matches.

So yes — the controller-manager acts as the supervisor ensuring the cluster actually does what the specs declare.

⸻

🔔 Example controller behavior

ReplicaSet Controller:

Desired replicas: 3
Actual running:   2
→ Creates 1 new Pod (POST /api/v1/namespaces/default/pods)

Node Controller:

Observed last heartbeat > 40s ago
→ Marks node "NotReady"
→ Evicts pods scheduled there

Service Controller:

New Service type=LoadBalancer
→ Calls cloud provider API (through Cloud Controller Manager)
→ Updates Service.status.loadBalancer.ingress

Each one is event-driven, watching through the API server just like the scheduler.

⸻

🧮 The controller pattern (ASCII)
```bash
 ┌─────────────────────────────┐
 │     Desired state (spec)    │  ← user / Deployment / YAML
 └──────────────▲──────────────┘
                │
                │ (watch)
                ▼
 ┌─────────────────────────────┐
 │  Controller (loop)          │
 │  - Compares desired vs actual
 │  - Makes API calls to fix
 │  - Updates status            │
 └──────────────▲──────────────┘
                │
                │ (update)
                ▼
 ┌─────────────────────────────┐
 │     Actual state (status)   │  ← kubelet, scheduler updates
 └─────────────────────────────┘
```

⸻

🧰 Key Points
 - Runs as a single binary (kube-controller-manager), but inside are many controllers.
 - Event-driven via watches, not polling (same as scheduler).
 - Talks only to the API server, never directly to etcd.
 - Reconciles desired vs actual state for every API resource type.
 - Writes changes back to the API server, triggering other components (scheduler, kubelets, etc.).

⸻

🔍 Commands to observe controller actions

# Check controller-manager logs
kubectl -n kube-system logs kube-controller-manager-minikube -f

# Watch deployment reconciliation
kubectl get rs,pods -w

# Inspect events from controllers
kubectl get events --sort-by=.lastTimestamp


⸻

🧭 TL;DR Summary

| Aspect | kube-scheduler | kube-controller-manager |
|--------|----------------|------------------------|
| Responsibility | Decides where Pods go | Ensures what exists and stays healthy |
| Drives | Pod placement | Everything else (replicas, services, nodes, volumes, etc.) |
| Mechanism | Watches unscheduled Pods | Watches many resource kinds |
| Writes | spec.nodeName | Creates, deletes, updates API objects |
| Analogy | The “dispatcher” | The “autopilot” / “maintenance crew” |
