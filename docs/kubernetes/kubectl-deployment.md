# Kubectl Deployment Process

## Overview

When you run the command `kubectl create deployment`, several components in the Kubernetes architecture work together to create and manage the deployment. Below is a simplified diagram illustrating the flow of actions that occur during this process:

```bash
kubectl → sends HTTPS request with the yaml/json payload
   │
   ▼
Kubernetes API Server
   ├─ Authenticates user (kubeconfig)
   ├─ Runs admission & validation webhooks
   ├─ Writes object to etcd
   └─ Responds to kubectl: "Created"

Meanwhile...
   │
   ▼
Controllers (Deployment, ReplicaSet, Scheduler)
   ├─ Watch API for new Deployments
   ├─ Create ReplicaSet + Pods
   └─ Assign Pods to Nodes

kubelet (on nodes)
   └─ Starts containers
```

## Kubectl

`kubectl` is the command-line tool used to interact with the Kubernetes API server. When you run `kubectl create deployment`, it constructs an HTTPS request containing the deployment specification in YAML or JSON format and sends it to the API server.

## Kubernetes API Server

The API server is the central management entity that processes requests from `kubectl` and other clients. Upon receiving the deployment request, it performs several actions:
1. **Authentication**: Verifies the identity of the user making the request using credentials from the kubeconfig file.
2. **Admission Control & Validation**: Runs any configured admission controllers and validation webhooks to ensure the request complies with cluster policies. Validates CRDs if applicable.
3. **Persistence**: Writes the deployment object to etcd, the cluster's backing store.
4. **Response**: Sends a response back to `kubectl` confirming the creation of the deployment.

## etcd

`etcd` is a distributed key-value store that serves as the persistent storage for all cluster data. When the API server writes the deployment object to etcd, it ensures that the desired state of the cluster is recorded and can be retrieved later.

## Controllers

A controller is just a control loop — a small program that:
	1.	Watches the API Server for objects of a certain kind (e.g. Deployment, Pod, Service).
	2.	Compares the actual cluster state with the desired state in etcd.
	3.	Takes action if there’s a difference (e.g. create, delete, or modify resources).

```bash
while true:
    desired = get_from_etcd()
    actual = observe_cluster()
    if desired != actual:
        make_them_match()
```


Controllers are split into two main categories:

1. **Built-in Controllers**: These are part of the Kubernetes control plane and include controllers for Deployments, ReplicaSets, DaemonSets, StatefulSets, etc.
2. **Custom Controllers**: These are user-defined controllers that can manage custom resources (CRDs) or extend Kubernetes functionality.
