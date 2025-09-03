# Chapter 3

## Exercise: 2.4. The project, step 9

### Move todo-app and todo-backend to project namespace.

Verify no deployments in default namespace:

```bash
➜ kubens default
Context "k3d-k3s-default" modified.
Active namespace is "default".
➜ k get deployments.apps
No resources found in default namespace.
```

create apps in project namespace:

```bash
➜ k create namespace project
namespace/project created
➜ k apply -f todo-app/manifests -f todo-backend/manifests -n project
deployment.apps/todo-app-deployment created
ingress.networking.k8s.io/todo-app-ingress created
service/todo-app-svc created
deployment.apps/todo-backend-deployment created
service/todo-backend-svc created
```

Verify app works.

```bash
➜ curl localhost:8081/
404 page not found
➜ k get deployments.apps
No resources found in default namespace.
➜ k get deployments.apps -n project
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
todo-app-deployment       0/1     1            0           22s
todo-backend-deployment   1/1     1            1           22s
```

Check why deployment is not ready:

```bash
➜ kubens project
Context "k3d-k3s-default" modified.
Active namespace is "project".
➜ k describe deployments.apps todo-app-deployment
Name:                   todo-app-deployment
Namespace:              project
CreationTimestamp:      Wed, 03 Sep 2025 13:59:06 +0200
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=todo-app
Replicas:               1 desired | 1 updated | 1 total | 0 available | 1 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=todo-app
  Containers:
   todo-app:
    Image:      docker.io/pjmartin/todo-app:2.2@sha256:eb882290c4c6c85786854ec37b7c5f9501f217c423fae6753e5e68d557319139
    Port:       <none>
    Host Port:  <none>
    Environment:
      TODO_BACKEND_URL:  http://todo-backend-svc:2345
      DATA_ROOT:         /app/data
    Mounts:
      /app/data from shared (rw)
  Volumes:
   shared:
    Type:          PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:     shared-volume-claim-0
    ReadOnly:      false
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    True    ReplicaSetUpdated
OldReplicaSets:  <none>
NewReplicaSet:   todo-app-deployment-6bdd5c6df4 (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  67s   deployment-controller  Scaled up replica set todo-app-deployment-6bdd5c6df4 to 1
```

Deployment is using persistent volume claim shared-volume-claim-0 which does not exist in the project namespace.

Create a new persistent volume and claim in project namespace on agent-1 node:

```bash

➜ docker exec -ti k3d-k3s-default-agent-1 /bin/sh
~ # mkdir /tmp/kube
~ #
➜ k apply -f manifests/infra/agent-1 -n project
persistentvolume/agent-1-pv created
persistentvolumeclaim/shared-volume-claim-1 created
```

update todo-app volume claim to use shared-volume-claim-1 in project namespace:

```bash
➜ k apply -f todo-app/manifests -n project
deployment.apps/todo-app-deployment configured
ingress.networking.k8s.io/todo-app-ingress unchanged
service/todo-app-svc unchanged
```

check if deployment now works.

```bash
➜ k get deployments.apps -n project
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
todo-app-deployment       1/1     1            1           4m28s
todo-backend-deployment   1/1     1            1           4m28s
➜ curl localhost:8081/

    <h1>The project App</h1>
    <img src="/image?ver=2025-09-03T12:03:46.771815+00:00" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>

    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
    %
```