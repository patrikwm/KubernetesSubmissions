# Chapter 2

# 1.9. More services

```bash
➜ cd ../log_output
➜ k apply -f manifests
deployment.apps/log-output-deployment created
ingress.networking.k8s.io/log-output-ingress created
service/log-output-svc created
➜ cd ../ping-pong_application
➜ k apply -f manifests
deployment.apps/ping-pong-deployment created
ingress.networking.k8s.io/ping-pong-ingress created
service/ping-pong-svc created
➜ k get deployments.apps ping-pong-deployment
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
ping-pong-deployment   0/1     1            0           95s
➜ k describe deployments.apps ping-pong-deployment
Name:                   ping-pong-deployment
Namespace:              default
CreationTimestamp:      Thu, 28 Aug 2025 14:34:25 +0200
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=pingpong
Replicas:               1 desired | 1 updated | 1 total | 0 available | 1 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=pingpong
  Containers:
   pingpong:
    Image:         pjmartin/pingpong:1.9
    Port:          <none>
    Host Port:     <none>
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    True    ReplicaSetUpdated
OldReplicaSets:  <none>
NewReplicaSet:   ping-pong-deployment-8fc885847 (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  102s  deployment-controller  Scaled up replica set ping-pong-deployment-8fc885847 to 1
➜ k get events
LAST SEEN   TYPE      REASON                   OBJECT                                        MESSAGE
35m         Normal    Killing                  pod/hashresponse-dep-6db44876-ndv9w           Stopping container hashresponse
58m         Normal    Scheduled                pod/log-output-deployment-86f659b74c-28c7x    Successfully assigned default/log-output-deployment-86f659b74c-28c7x to k3d-k3s-default-agent-0
58m         Normal    Pulling                  pod/log-output-deployment-86f659b74c-28c7x    Pulling image "pjmartin/log_output:1.7"
58m         Normal    Pulled                   pod/log-output-deployment-86f659b74c-28c7x    Successfully pulled image "pjmartin/log_output:1.7" in 6.022s (6.022s including waiting). Image size: 59990387 bytes.
58m         Normal    Created                  pod/log-output-deployment-86f659b74c-28c7x    Created container logoutput
58m         Normal    Started                  pod/log-output-deployment-86f659b74c-28c7x    Started container logoutput
36m         Normal    Killing                  pod/log-output-deployment-86f659b74c-28c7x    Stopping container logoutput
2m36s       Normal    Scheduled                pod/log-output-deployment-86f659b74c-n59nr    Successfully assigned default/log-output-deployment-86f659b74c-n59nr to k3d-k3s-default-agent-0
2m36s       Normal    Pulled                   pod/log-output-deployment-86f659b74c-n59nr    Container image "pjmartin/log_output:1.7" already present on machine
2m36s       Normal    Created                  pod/log-output-deployment-86f659b74c-n59nr    Created container logoutput
2m36s       Normal    Started                  pod/log-output-deployment-86f659b74c-n59nr    Started container logoutput
58m         Normal    SuccessfulCreate         replicaset/log-output-deployment-86f659b74c   Created pod: log-output-deployment-86f659b74c-28c7x
2m36s       Normal    SuccessfulCreate         replicaset/log-output-deployment-86f659b74c   Created pod: log-output-deployment-86f659b74c-n59nr
58m         Normal    ScalingReplicaSet        deployment/log-output-deployment              Scaled up replica set log-output-deployment-86f659b74c to 1
2m36s       Normal    ScalingReplicaSet        deployment/log-output-deployment              Scaled up replica set log-output-deployment-86f659b74c to 1
2m36s       Warning   FailedToCreateEndpoint   endpoints/log-output-svc                      Failed to create endpoint for service default/log-output-svc: endpoints "log-output-svc" already exists
2m25s       Normal    Scheduled                pod/ping-pong-deployment-8fc885847-bjvnt      Successfully assigned default/ping-pong-deployment-8fc885847-bjvnt to k3d-k3s-default-agent-1
64s         Normal    Pulling                  pod/ping-pong-deployment-8fc885847-bjvnt      Pulling image "pjmartin/pingpong:1.9"
64s         Warning   Failed                   pod/ping-pong-deployment-8fc885847-bjvnt      Failed to pull image "pjmartin/pingpong:1.9": failed to pull and unpack image "docker.io/pjmartin/pingpong:1.9": failed to resolve reference "docker.io/pjmartin/pingpong:1.9": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
64s         Warning   Failed                   pod/ping-pong-deployment-8fc885847-bjvnt      Error: ErrImagePull
27s         Normal    BackOff                  pod/ping-pong-deployment-8fc885847-bjvnt      Back-off pulling image "pjmartin/pingpong:1.9"
40s         Warning   Failed                   pod/ping-pong-deployment-8fc885847-bjvnt      Error: ImagePullBackOff
2m25s       Normal    SuccessfulCreate         replicaset/ping-pong-deployment-8fc885847     Created pod: ping-pong-deployment-8fc885847-bjvnt
2m25s       Normal    ScalingReplicaSet        deployment/ping-pong-deployment               Scaled up replica set ping-pong-deployment-8fc885847 to 1
➜ docker build . --tag pjmartin/pingpong:1.9 --push
[+] Building 7.6s (13/13) FINISHED                                                                                   docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                 0.0s
 => => transferring dockerfile: 201B                                                                                                 0.0s
 => [internal] load metadata for docker.io/library/python:3.10.13-slim                                                               0.9s
 => [auth] library/python:pull token for registry-1.docker.io                                                                        0.0s
 => [internal] load .dockerignore                                                                                                    0.0s
 => => transferring context: 2B                                                                                                      0.0s
 => [1/5] FROM docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922         0.0s
 => => resolve docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922         0.0s
 => [internal] load build context                                                                                                    0.3s
 => => transferring context: 22.50MB                                                                                                 0.3s
 => CACHED [2/5] WORKDIR /app                                                                                                        0.0s
 => CACHED [3/5] COPY requirements.txt requirements.txt                                                                              0.0s
 => CACHED [4/5] RUN pip install -r requirements.txt                                                                                 0.0s
 => [5/5] COPY . .                                                                                                                   0.2s
 => exporting to image                                                                                                               6.1s
 => => exporting layers                                                                                                              0.6s
 => => exporting manifest sha256:3d980009d8e861e966d1b3684ffa3ec6568d979ae2093cbdc742fb902cf83038                                    0.0s
 => => exporting config sha256:6ce0c971bcc2496f8b22c77f664b3cf1a500ace028bfc8dc9532f3f93aa43321                                      0.0s
 => => exporting attestation manifest sha256:c68256fdc4e2e642c570b82e473bbf20054c7ecaf018a4ff88b01ceaac4819ec                        0.0s
 => => exporting manifest list sha256:6a03e8cb717f783f96a8b63accd51d82c578fb77eac0acc416e9be86c40b1e23                               0.0s
 => => naming to docker.io/pjmartin/pingpong:1.9                                                                                     0.0s
 => => unpacking to docker.io/pjmartin/pingpong:1.9                                                                                  0.1s
 => => pushing layers                                                                                                                2.7s
 => => pushing manifest for docker.io/pjmartin/pingpong:1.9@sha256:6a03e8cb717f783f96a8b63accd51d82c578fb77eac0acc416e9be86c40b1e23  2.6s
 => [auth] pjmartin/pingpong:pull,push token for registry-1.docker.io                                                                0.0s
 => [auth] pjmartin/pingpong:pull,push pjmartin/todo_app:pull token for registry-1.docker.io                                         0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/qtn4aysg7pfzejdg3gyigyvxw
➜ k get pods
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-86f659b74c-n59nr   1/1     Running   0          6m46s
ping-pong-deployment-8fc885847-bjvnt     1/1     Running   0          6m35s
todo-app-deployment-bd879fdf5-ltjtw      1/1     Running   0          112m
➜ curl localhost:8081
{"random_string":"fk3DnLYlUe","timestamp":"2025-08-28T12:41:05.376Z"}
➜ curl localhost:8081/pingpong
pong 0%
➜ curl localhost:8081/pingpong
pong 1%
➜ curl localhost:8081/pingpong
pong 2%
➜ k describe pod ping-pong-deployment-8fc885847-bjvnt
Name:             ping-pong-deployment-8fc885847-bjvnt
Namespace:        default
Priority:         0
Service Account:  default
Node:             k3d-k3s-default-agent-1/172.18.0.5
Start Time:       Thu, 28 Aug 2025 14:34:25 +0200
Labels:           app=pingpong
                  pod-template-hash=8fc885847
Annotations:      <none>
Status:           Running
IP:               10.42.1.5
IPs:
  IP:           10.42.1.5
Controlled By:  ReplicaSet/ping-pong-deployment-8fc885847
Containers:
  pingpong:
    Container ID:   containerd://b00c43bf3de705aaee0cddabe8ea96e3d02cf9ab0bb25eef7e363e510604186e
    Image:          pjmartin/pingpong:1.9
    Image ID:       docker.io/pjmartin/pingpong@sha256:6a03e8cb717f783f96a8b63accd51d82c578fb77eac0acc416e9be86c40b1e23
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Thu, 28 Aug 2025 14:40:11 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-5wtdb (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  kube-api-access-5wtdb:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                     From               Message
  ----     ------     ----                    ----               -------
  Normal   Scheduled  8m50s                   default-scheduler  Successfully assigned default/ping-pong-deployment-8fc885847-bjvnt to k3d-k3s-default-agent-1
  Normal   Pulling    7m30s (x4 over 8m51s)   kubelet            Pulling image "pjmartin/pingpong:1.9"
  Warning  Failed     7m30s (x4 over 8m50s)   kubelet            Failed to pull image "pjmartin/pingpong:1.9": failed to pull and unpack image "docker.io/pjmartin/pingpong:1.9": failed to resolve reference "docker.io/pjmartin/pingpong:1.9": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  Warning  Failed     7m30s (x4 over 8m50s)   kubelet            Error: ErrImagePull
  Warning  Failed     7m6s (x6 over 8m50s)    kubelet            Error: ImagePullBackOff
  Normal   BackOff    3m39s (x21 over 8m50s)  kubelet            Back-off pulling image "pjmartin/pingpong:1.9"
```

Did some changes so both pingpong and log_output service use the same ClusterIP port since they do not need to be unique like NodePort.

```bash
➜ k describe service log-output-svc
Name:                     log-output-svc
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=logoutput
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.234.171
IPs:                      10.43.234.171
Port:                     <unset>  2345/TCP
TargetPort:               3000/TCP
Endpoints:                10.42.3.6:3000
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
➜ k describe service ping-pong-svc
Name:                     ping-pong-svc
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=pingpong
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.143.29
IPs:                      10.43.143.29
Port:                     http  2346/TCP
TargetPort:               3000/TCP
Endpoints:                10.42.1.5:3000
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```

---

# PostgreSQL Integration

## Overview

The ping-pong application has been converted from Flask to FastAPI and now includes PostgreSQL database integration. The counter is persisted in a PostgreSQL database instead of local files.

## Features

- **FastAPI Framework**: Migrated from Flask to FastAPI for better async support
- **PostgreSQL Integration**: Counter values are stored in PostgreSQL database
- **Async Operations**: All database operations are asynchronous
- **Health Check**: `/health` endpoint to verify database connectivity
- **Backward Compatibility**: File logging is maintained as backup

## Endpoints

- `GET /pingpong` - Increment and return the ping-pong counter
- `GET /pings` - Get current counter value without incrementing
- `GET /health` - Database connectivity health check

## Database Schema

```sql
CREATE TABLE ping_pong (
    id SERIAL PRIMARY KEY,
    counter INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Environment Variables

The application supports the following environment variables:

```bash
# PostgreSQL Configuration
POSTGRES_HOST=postgres-svc
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=example

# Application Configuration
PORT=3000
DATA_ROOT=/app/data
LOG_LEVEL=INFO
```

## Deployment Steps

1. **Deploy PostgreSQL StatefulSet**:
   ```bash
   kubectl apply -f ../postgres/manifests/postgres.yaml
   ```

2. **Build and Push Docker Image**:
   ```bash
   docker build . --tag your-registry/pingpong:latest --push
   ```

3. **Update deployment.yaml** with PostgreSQL environment variables (already done)

4. **Deploy the Application**:
   ```bash
   kubectl apply -f manifests/
   ```

## Testing

1. **Test Database Connectivity**:
   ```bash
   python test_db.py
   ```

2. **Test Application Endpoints**:
   ```bash
   curl localhost:8081/health
   curl localhost:8081/pingpong
   curl localhost:8081/pings
   ```

## Dependencies

- `fastapi==0.104.1` - Web framework
- `uvicorn==0.24.0` - ASGI server
- `asyncpg==0.29.0` - PostgreSQL async driver
- `databases==0.8.0` - Database abstraction layer