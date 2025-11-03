# Kubernetes Scheduler

## Overview

The `kube-scheduler` is one of the core control plane components in Kubernetes. Its main job is to assign Pods to Nodes based on resource availability, constraints, affinities, and scoring policies.

When a new Pod is created (via `kubectl apply`, a Deployment, or a controller), it initially has no assigned node:

```yaml
spec:
  nodeName: ""
```

The scheduler's job is to decide where that Pod should run.

---

## Scheduler Flow

```bash
┌────────────────────────────────────────────┐
│          kubectl apply -f pod.yaml         │
└────────────────────────────────────────────┘
                 │
                 ▼
────────────────────────────────────────────────────────────
             KUBE-APISERVER
────────────────────────────────────────────────────────────
  • Validates the Pod and writes it to etcd
  • Pod has no `spec.nodeName` yet (unscheduled)
                 │
                 ▼
────────────────────────────────────────────────────────────
             KUBE-SCHEDULER
────────────────────────────────────────────────────────────
  • Watches the API server for unscheduled Pods
  • Maintains cache of:
        - All Nodes and their capacities
        - Existing Pods (for affinities & resources)
        - Storage, volumes, zones, etc.
  • When a new Pod appears:
        1. Filters nodes that **can't** host it
        2. Scores remaining nodes using plugins
        3. Selects the highest-scoring node
        4. Writes the decision back via the API server
           → sets `spec.nodeName=<chosen-node>`
                 │
                 ▼
────────────────────────────────────────────────────────────
             API SERVER ←→ ETCD
────────────────────────────────────────────────────────────
  • Persists scheduler's binding decision
  • Kubelet on that node will now see the Pod
                 │
                 ▼
────────────────────────────────────────────────────────────
                 KUBELET
────────────────────────────────────────────────────────────
  • Watches the API server for Pods assigned to its node
  • Starts containers through the CRI (containerd, CRI-O)
  • Updates Pod status (Pending → Running → …)
                 │
                 ▼
────────────────────────────────────────────────────────────
            kubectl get pods → Running
────────────────────────────────────────────────────────────
```

---

## Scheduling Cycle

The scheduler operates in two main phases using the scheduling framework.

### 1. Scheduling Cycle

- **Queue Sort:** Pick next Pod to schedule (from internal queues)
- **PreFilter:** Quick sanity checks (resources, affinity, etc.)
- **Filter:** Eliminate nodes that don't satisfy requirements
- **PostFilter (optional):** Try preemption if no node fits
- **Score:** Rank feasible nodes with scoring plugins
- **Normalize:** Adjust scores and pick the highest

### 2. Binding Cycle

- **Reserve:** Temporarily reserve node resources
- **Permit:** Allow other plugins to approve/deny
- **Bind:** Write the chosen node via API (`/binding` subresource)
- **Unreserve / PostBind:** Cleanup hooks if needed

---

## Common Scoring Plugins

| Plugin | Purpose |
|--------|---------|
| **NodeResourcesFit** | Prefers nodes with enough free CPU/memory |
| **ImageLocality** | Prefers nodes that already have the image pulled |
| **InterPodAffinity** | Honors pod affinity / anti-affinity rules |
| **TopologySpread** | Spreads pods evenly across zones/nodes |
| **NodeAffinity** | Honors nodeSelector and nodeAffinity |
| **BalancedAllocation** | Balances resource usage across nodes |

---

## Event-Driven, Not Polling

The scheduler does not poll like a cron job. It uses Kubernetes' **watch mechanism**, reacting instantly when:

- A new unscheduled Pod is created
- A Node's resources or taints change
- A previously unschedulable Pod becomes feasible

> **Important:** The scheduler always works through the API server, never talking directly to etcd.

---

## Binding Example

After scheduling, the scheduler updates the API server:

```yaml
spec:
  nodeName: minikube
```

From there, only the kubelet on that node will act on the Pod and start containers.

---

## Customizing Scheduling

| Goal | Solution |
|------|----------|
| Spread Pods evenly across nodes | Use `topologySpreadConstraints` |
| Avoid placing same app on same node | Use `podAntiAffinity` |
| Influence placement globally | Configure custom scheduler profiles or plugin weights |
| Create your own logic | Implement custom scheduler plugins or extenders |

---

## Key Takeaways

- The scheduler is a **brain that decides where things run** — not how they run
- It's **event-driven**, not time-driven
- It reads cluster state via the API server and writes scheduling decisions back through the same API
- The **kubelet** is the component that actually runs containers after scheduling

---

## Quick Commands for Observing Scheduling

### Watch scheduling decisions
```bash
kubectl get events --sort-by=.lastTimestamp | grep Scheduled
```

### View scheduler logs
```bash
kubectl -n kube-system logs kube-scheduler-minikube -f
```

### Check Pod placement
```bash
kubectl get pods -o wide
```

---

## Summary Diagram

```
┌─────────────┐      ┌──────────────┐      ┌──────────┐
│  API Server │◄────►│   Scheduler  │◄────►│  etcd    │
└──────▲──────┘      └──────▲───────┘      └────▲─────┘
       │ (watch + bind)     │ (cache)            │
       │                    │                    │
       ▼                    ▼                    ▼
┌──────────────┐    watches assigned pods    ┌─────────────┐
│   Kubelet    │────────────────────────────►│   Node(s)   │
└──────────────┘                            └─────────────┘
```

---

## Summary

The Kubernetes Scheduler constantly watches for unscheduled Pods, filters and scores all available nodes, and binds each Pod to the optimal node. **It never runs containers** — it only makes placement decisions that the kubelet later executes.
