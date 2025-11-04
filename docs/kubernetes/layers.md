# Kubernetes Control Hierarchy

Kubernetes relies on a stack of control-plane loops and node-level components to turn declarative manifests into running containers. This guide summarizes the layers from your Deployment down to the host kernel and highlights the responsibilities at each tier.

## Layered Overview

| Level | Component | Responsibility | Runs Where |
|-------|-----------|----------------|------------|
| High-level controller | Deployment controller | Keeps a ReplicaSet aligned with the Deployment spec | Control plane |
| High-level controller | ReplicaSet controller | Ensures the desired number of Pods exist | Control plane |
| Scheduling | Scheduler | Chooses which node runs each Pod | Control plane |
| Execution | Kubelet | Realizes Pods on the node (images, volumes, probes) | Worker node |
| Runtime interface | CRI (Container Runtime Interface) | API between kubelet and the container runtime | Worker node |
| Networking interface | CNI (Container Network Interface) | Provisions Pod networking, IPs, and policies | Worker node |
| Storage interface | CSI (Container Storage Interface) | Attaches and mounts persistent volumes | Worker node |
| Runtime | containerd / CRI-O / Docker shim | Pulls images, launches containers, monitors lifecycle | Worker node |
| Operating system | Linux kernel (namespaces, cgroups, iptables, overlayfs) | Provides isolation and networking primitives | Worker node |
| Hardware | CPU / memory / disk / NICs | Supplies the actual compute resources | Host machine |

## Control-Plane Reconcilers

### Deployment controller

- Watches the API for new or updated Deployments.
- Creates or updates ReplicaSets so `.spec.replicas` and the Pod template remain in sync.
- Initiates rolling updates, rollbacks, and scale operations.

### ReplicaSet controller

- Ensures the ReplicaSet has the desired number of Pods matching the template.
- Creates replacement Pods when failures or evictions reduce the count.
- Deletes surplus Pods after a scale-down.

### Scheduler

- Watches for Pods without a `spec.nodeName`.
- Scores candidate nodes based on resources, taints, affinities, topology, and policies.
- Binds each Pod to a node by updating the Pod spec and writing back through the API server.

## Node Execution Stack

Once the scheduler assigns a Pod, the kubelet on the chosen node orchestrates several host-level interfaces to make the Pod real.

### Kubelet (node agent)

- Watches the API server for Pods scheduled to its node.
- Coordinates container creation, liveness/readiness probes, and volume lifecycle.
- Reports Pod and Node status back to the API server.

### Container Runtime Interface (CRI)

- gRPC API that abstracts container runtimes (`RunPodSandbox`, `CreateContainer`, `StartContainer`, etc.).
- Allows kubelet to work with different runtimes (containerd, CRI-O, Docker shim) without special casing.
- Each call maps to low-level actions like creating namespaces, cgroups, and processes.

### Container runtime (containerd / CRI-O)

- Pulls images from registries and unpacks filesystem layers (overlayfs).
- Launches container processes via `runc` (or another OCI runtime) with isolated namespaces and cgroups.
- Streams logs, tracks exit codes, and reports lifecycle events back through CRI.

### Container Network Interface (CNI)

- Configures networking after the Pod sandbox exists.
- Creates veth pairs, attaches one end to the Pod namespace, and connects the other to the host network (bridge, overlay, or SR-IOV).
- Allocates Pod IP addresses (IPAM) and programs routes, NAT, and network policies.
- Returns the assigned Pod IP to the kubelet, which records it via the API server.

### Container Storage Interface (CSI)

- Handles persistent volume lifecycle (attach, stage, publish).
- Mounts storage (EBS, Ceph, NFS, hostPath, etc.) into the Pod filesystem.
- Coordinates volume teardown when Pods terminate.

### Linux kernel

- Provides the isolation primitives Kubernetes leans on:
  - **Namespaces** for process, network, mount, PID, IPC, and user separation.
  - **cgroups** for CPU, memory, and I/O quotas.
  - **Netfilter / iptables / nftables** for routing, NAT, and service VIPs.
  - **veth pairs & bridges** to connect Pod namespaces to the node network.
  - **overlayfs** to merge image layers with writable containers.

### Hardware resources

- Physical or virtual CPU, memory, disks, and NICs ultimately execute workloads.
- Kubernetes schedulers and controllers treat these as consumable resources exposed by the node.

## End-to-End Flow: From `kubectl` to Kernel

1. `kubectl apply -f deployment.yaml`
2. API server authenticates, authorizes, runs admission webhooks, and writes objects to `etcd`.
3. Deployment controller creates or updates a ReplicaSet; ReplicaSet controller creates Pods.
4. Scheduler assigns each pending Pod to a node.
5. Kubelet notices the assignment and calls CRI to create the Pod sandbox.
6. CNI configures networking; CSI mounts requested volumes.
7. Container runtime launches containers via `runc`, which relies on Linux namespaces and cgroups.
8. Kubelet reports status back through the API server, and `kubectl get pods` reflects the running state.

## Quick Reference: Host-Level Interfaces

| Interface / Layer | Examples | Primary Purpose |
|-------------------|----------|-----------------|
| CRI | containerd, CRI-O, Docker shim | Standard API the kubelet uses to manage containers |
| CNI | Calico, Flannel, Cilium | Provision Pod networking and IP addresses |
| CSI | Ceph, AWS EBS, hostPath | Provide and mount persistent storage |
| OCI runtime | runc, gVisor, Kata | Spawn containers inside namespaces & cgroups |
| Kernel / OS | Linux | Enforces isolation, networking, and storage primitives |

## Key Takeaways

- The control plane continuously reconciles desired state (Deployments) into concrete workloads (Pods).
- The kubelet is the conductor on each node, driving CRI, CNI, and CSI to materialize Pods.
- Standard interfaces (CRI/CNI/CSI) let Kubernetes swap implementations without changing kubelet logic.
- Linux primitives power container isolation; Kubernetes layers higher-order automation on top.


