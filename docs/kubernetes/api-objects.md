# Kubernetes API Objects & Versions

Kubernetes resources (Pods, Deployments, Ingresses, CRDs, etc.) are versioned by API group and version.
In every manifest you set:

apiVersion: <group>/<version>   # e.g. apps/v1, networking.k8s.io/v1
kind: <ResourceKind>            # e.g. Deployment, Ingress

This guide shows how to discover what your cluster supports, how to pick the right apiVersion, and how to check deprecations.

⸻

🔎 What API groups/versions are available?

Quick list of all served versions

kubectl api-versions

Outputs entries like:

admissionregistration.k8s.io/v1
apps/v1
batch/v1
networking.k8s.io/v1

List resources (kinds) per apiVersion

kubectl api-resources
# or with extra columns:
kubectl api-resources -o wide

Filter by group:

```bash
kubectl api-resources --api-group=apps
kubectl api-resources --api-group=networking.k8s.io
```

Server + client version (helpful context)

kubectl version --short
# or detailed:
kubectl version -o yaml


⸻

🧭 Find the right apiVersion for a specific resource

1) Use kubectl explain

```bash
# Show which versions support Deployment and its schema
kubectl explain deployment                # uses preferred group/version
kubectl explain deployment --api-version=apps/v1
kubectl explain ingress --api-version=networking.k8s.io/v1
```

This confirms both the supported version and the fields you can use.

2) Ask the API Server’s discovery endpoints (advanced)

```bash
# Core group (pods, services, configmaps…)
kubectl get --raw /api | jq

# Named groups (apps, networking, batch…)
kubectl get --raw /apis | jq
kubectl get --raw /apis/apps | jq
kubectl get --raw /apis/networking.k8s.io | jq

# Preferred version for a group:
kubectl get --raw /apis/apps | jq '.preferredVersion.version'
````

Tip: if jq isn’t installed, omit the pipe to jq.

⸻

🧩 Common, modern apiVersions (K8s 1.24+)

| Kind | apiVersion |
|------|------------|
| Pod, Service, ConfigMap, Secret | v1 (core group) |
| Deployment, DaemonSet, StatefulSet, ReplicaSet | apps/v1 |
| Job, CronJob | batch/v1 |
| Ingress, IngressClass, NetworkPolicy | networking.k8s.io/v1 |
| HorizontalPodAutoscaler | autoscaling/v2 |
| PriorityClass | scheduling.k8s.io/v1 |
| PodDisruptionBudget | policy/v1 |
| PersistentVolume, PersistentVolumeClaim | v1 |
| StorageClass | storage.k8s.io/v1 |
| CustomResourceDefinition (CRD) | apiextensions.k8s.io/v1 |

If your cluster is older/newer, always validate with kubectl api-resources / kubectl explain.

⸻

## 🧪 Verify a manifest before applying

Dry-run against the API server (validates kind + apiVersion + schema):

```bash
kubectl apply -f my.yaml --server-side --dry-run=server
# or
kubectl apply -f my.yaml --dry-run=client   # syntax only, no server check
```

⸻

## 🧱 Custom Resources (CRDs)

When operators/installations add CRDs, they create new API groups/versions.

List CRDs and their served/storage versions:

```bash
kubectl get crds
kubectl get crd <name> -o yaml | yq '.spec.versions[] | {name, served, storage}'
# (omit `| yq ...` if you don't have yq)
```

CRDs define their own apiVersion: <your.group>/<version> which you’ll also see via:

```bash
kubectl api-resources | grep <your.group>
```

⸻

## 🚪 Ingress specifics

Modern clusters use:

- Ingress → networking.k8s.io/v1
- IngressClass → networking.k8s.io/v1

Confirm what your cluster serves:

```bash
kubectl api-resources --api-group=networking.k8s.io
kubectl explain ingress --api-version=networking.k8s.io/v1
```

⸻

## 🛑 Deprecations & migration hints

- The API server returns deprecation warnings on use of deprecated versions. Show them by adding verbosity:

```bash
kubectl --v=6 get deploy
```

- Switch manifests to the group/version shown by:

```bash
kubectl api-resources | grep -i <kind>
kubectl explain <kind> --api-version=<group>/<version>
```

- When multiple versions are served for a CRD, prefer the preferred or storage version reported in the CRD spec.

⸻

## 🧰 Cheatsheet

```bash
# All served API versions
kubectl api-versions

# All resource kinds grouped by API group
kubectl api-resources -o wide

# Resources in a specific group
kubectl api-resources --api-group=apps

# Schema & fields for a kind (and confirm version)
kubectl explain deployment --api-version=apps/v1

# Discovery (advanced)
kubectl get --raw /apis/apps | jq
kubectl get --raw /apis/apps | jq '.preferredVersion.version'

# CRDs and their versions
kubectl get crds
kubectl get crd <name> -o yaml | less
```

⸻

## 🧠 Mental model

1. Discovery: the API server advertises what it serves.
2. Validation: your manifest’s apiVersion/kind must match a served resource + schema.
3. Reconciliation: controllers act only after the object is accepted by the API server.
4. CRDs extend the API: installing operators adds new groups/versions you’ll see via discovery.

⸻

Rule of thumb:

Always confirm apiVersion with kubectl api-resources and kubectl explain on your cluster before writing manifests — API surface can vary by version and installed CRDs.

⸻
