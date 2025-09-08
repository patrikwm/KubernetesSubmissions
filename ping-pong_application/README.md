# Chapter 4

# Exercise: 3.1. Pingpong AKS

## Deploy postgres

Set up the postgres database with old config.

```bash
./script/deploy-postgres.sh.sh
secret/postgres-secrets created
service/postgres-svc created
statefulset.apps/postgres-stset created
```

local-path does not seem to work in AKS.

```bash
➜ k get statefulsets.apps
NAME             READY   AGE
postgres-stset   0/1     58s
➜ k get events
LAST SEEN   TYPE      REASON               OBJECT                                                         MESSAGE
11s         Warning   ProvisioningFailed   persistentvolumeclaim/postgres-data-storage-postgres-stset-0   storageclass.storage.k8s.io "local-path" not found
4m38s       Warning   FailedScheduling     pod/postgres-stset-0                                           0/5 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/5 nodes are available: 5 Preemption is not helpful for scheduling.
62s         Warning   FailedScheduling     pod/postgres-stset-0                                           0/5 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/5 nodes are available: 5 Preemption is not helpful for scheduling.
4m38s       Normal    SuccessfulCreate     statefulset/postgres-stset                                     create Claim postgres-data-storage-postgres-stset-0 Pod postgres-stset-0 in StatefulSet postgres-stset success
4m38s       Normal    SuccessfulCreate     statefulset/postgres-stset                                     create Pod postgres-stset-0 in StatefulSet postgres-stset successful
62s         Normal    SuccessfulCreate     statefulset/postgres-stset                                     create Pod postgres-stset-0 in StatefulSet postgres-stset successful
```

Get storageclass and see that local-path is not there.

```bash
➜ k get storageclass
NAME                    PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
azurefile               file.csi.azure.com   Delete          Immediate              true                   39m
azurefile-csi           file.csi.azure.com   Delete          Immediate              true                   39m
azurefile-csi-premium   file.csi.azure.com   Delete          Immediate              true                   39m
azurefile-premium       file.csi.azure.com   Delete          Immediate              true                   39m
default (default)       disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   39m
managed                 disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   39m
managed-csi             disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   39m
managed-csi-premium     disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   39m
managed-premium         disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   39m
```

Delete StatefulSet of postgres, Update the storage class to managed-csi, and redeploy.

```bash
➜ k delete statefulsets.apps postgres-stset
statefulset.apps "postgres-stset" deleted

➜ k get statefulsets.apps

➜ ./script/deploy-postgres.sh.sh
secret/postgres-secrets unchanged
service/postgres-svc unchanged
statefulset.apps/postgres-stset created

➜ k get events
LAST SEEN   TYPE      REASON                  OBJECT                                                         MESSAGE
6m31s       Warning   ProvisioningFailed      persistentvolumeclaim/postgres-data-storage-postgres-stset-0   storageclass.storage.k8s.io "local-path" not found
16s         Normal    WaitForFirstConsumer    persistentvolumeclaim/postgres-data-storage-postgres-stset-0   waiting for first consumer to be created before binding
16s         Normal    ExternalProvisioning    persistentvolumeclaim/postgres-data-storage-postgres-stset-0   Waiting for a volume to be created either by the external provisioner 'disk.csi.azure.com' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
16s         Normal    Provisioning            persistentvolumeclaim/postgres-data-storage-postgres-stset-0   External provisioner is provisioning volume for claim "database/postgres-data-storage-postgres-stset-0"
14s         Normal    ProvisioningSucceeded   persistentvolumeclaim/postgres-data-storage-postgres-stset-0   Successfully provisioned volume pvc-0ccd6737-66b6-4326-9548-3f70cf05d7a3
21m         Warning   FailedScheduling        pod/postgres-stset-0                                           0/5 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/5 nodes are available: 5 Preemption is not helpful for scheduling.
7m54s       Warning   FailedScheduling        pod/postgres-stset-0                                           0/5 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/5 nodes are available: 5 Preemption is not helpful for scheduling.
14s         Normal    Scheduled               pod/postgres-stset-0                                           Successfully assigned database/postgres-stset-0 to aks-nodepool1-32045435-vmss000001
21m         Normal    SuccessfulCreate        statefulset/postgres-stset                                     create Claim postgres-data-storage-postgres-stset-0 Pod postgres-stset-0 in StatefulSet postgres-stset success
21m         Normal    SuccessfulCreate        statefulset/postgres-stset                                     create Pod postgres-stset-0 in StatefulSet postgres-stset successful
18m         Normal    SuccessfulCreate        statefulset/postgres-stset                                     create Pod postgres-stset-0 in StatefulSet postgres-stset successful
6m16s       Normal    SuccessfulDelete        statefulset/postgres-stset                                     delete Pod postgres-stset-0 in StatefulSet postgres-stset successful
16s         Normal    SuccessfulCreate        statefulset/postgres-stset                                     create Claim postgres-data-storage-postgres-stset-0 Pod postgres-stset-0 in StatefulSet postgres-stset success
16s         Normal    SuccessfulCreate        statefulset/postgres-stset                                     create Pod postgres-stset-0 in StatefulSet postgres-stset successful

➜ k get statefulsets.apps
NAME             READY   AGE
postgres-stset   0/1     19m
```

Something is still not working correctly. Check the logs of the pod.

```bash
➜ k logs -f postgres-stset-0
Error from server (BadRequest): container "postgres" in pod "postgres-stset-0" is waiting to start: ContainerCreating
```

Seems that the pod is stuck in ContainerCreating. Check describe.

```bash
➜ k describe pod postgres-stset-0
Name:             postgres-stset-0
Namespace:        database
Priority:         0
Service Account:  default
Node:             aks-nodepool1-32045435-vmss000001/10.224.0.6
Start Time:       Fri, 05 Sep 2025 14:38:50 +0200
Labels:           app=postgres
                  apps.kubernetes.io/pod-index=0
                  controller-revision-hash=postgres-stset-8d59f486c
                  statefulset.kubernetes.io/pod-name=postgres-stset-0
Annotations:      <none>
Status:           Pending
IP:
IPs:              <none>
Controlled By:    StatefulSet/postgres-stset
Containers:
  postgres:
    Container ID:
    Image:          postgres:17.6
    Image ID:
    Port:           5432/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       ContainerCreating
    Ready:          False
    Restart Count:  0
    Environment Variables from:
      postgres-secrets  Secret  Optional: false
    Environment:        <none>
    Mounts:
      /data from postgres-data-storage (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-dwnj2 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   False
  Initialized                 True
  Ready                       False
  ContainersReady             False
  PodScheduled                True
Volumes:
  postgres-data-storage:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  postgres-data-storage-postgres-stset-0
    ReadOnly:   false
  kube-api-access-dwnj2:
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
  Type    Reason                  Age   From                     Message
  ----    ------                  ----  ----                     -------
  Normal  Scheduled               26m   default-scheduler        Successfully assigned database/postgres-stset-0 to aks-nodepool1-32045435-vmss000001
  Normal  SuccessfulAttachVolume  26m   attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-0ccd6737-66b6-4326-9548-3f70cf05d7a3"
  Normal  Pulling                 26m   kubelet                  Pulling image "postgres:17.6"
```

Pod is stuck at pulling the image. I will try to change the image to be fully qualified and redeploy.

```bash
➜ k delete statefulsets.apps postgres-stset
statefulset.apps "postgres-stset" deleted

➜ cat postgres/manifests/postgres-stset.yaml |grep image
          image: docker.io/library/postgres:17.6

➜ ./script/deploy-postgres.sh.sh
secret/postgres-secrets unchanged
service/postgres-svc unchanged
statefulset.apps/postgres-stset created

➜ k logs -f postgres-stset-0
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.utf8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/data ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default "max_connections" ... 100
selecting default "shared_buffers" ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok


Success. You can now start the database server using:

    pg_ctl -D /var/lib/postgresql/data -l logfile start

initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.
waiting for server to start....2025-09-05 14:11:28.531 UTC [48] LOG:  starting PostgreSQL 17.6 (Debian 17.6-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
2025-09-05 14:11:28.537 UTC [48] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2025-09-05 14:11:28.551 UTC [51] LOG:  database system was shut down at 2025-09-05 14:11:28 UTC
2025-09-05 14:11:28.562 UTC [48] LOG:  database system is ready to accept connections
 done
server started

/usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*

2025-09-05 14:11:28.641 UTC [48] LOG:  received fast shutdown request
waiting for server to shut down....2025-09-05 14:11:28.648 UTC [48] LOG:  aborting any active transactions
2025-09-05 14:11:28.650 UTC [48] LOG:  background worker "logical replication launcher" (PID 54) exited with exit code 1
2025-09-05 14:11:28.653 UTC [49] LOG:  shutting down
2025-09-05 14:11:28.657 UTC [49] LOG:  checkpoint starting: shutdown immediate
2025-09-05 14:11:28.679 UTC [49] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.006 s, sync=0.003 s, total=0.026 s; sync files=2, longest=0.002 s, average=0.002 s; distance=0 kB, estimate=0 kB; lsn=0/14ED7B8, redo lsn=0/14ED7B8
2025-09-05 14:11:28.683 UTC [48] LOG:  database system is shut down
 done
server stopped

PostgreSQL init process complete; ready for start up.

2025-09-05 14:11:28.773 UTC [1] LOG:  starting PostgreSQL 17.6 (Debian 17.6-1.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
2025-09-05 14:11:28.773 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2025-09-05 14:11:28.774 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2025-09-05 14:11:28.783 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2025-09-05 14:11:28.795 UTC [62] LOG:  database system was shut down at 2025-09-05 14:11:28 UTC
2025-09-05 14:11:28.805 UTC [1] LOG:  database system is ready to accept connections
```
Success!

## Deploy ping pong application

```bash
Since im taking up and down the cluster i created some deployment scripts in `./script` to make my life easier.

Deploy ping pong application.

```bash
➜ chmod +x ./script/deploy-ping-pong.sh
➜ ./script/deploy-ping-pong.sh
namespace/exercises created
secret/ping-pong-secrets created
configmap/log-output-config created
deployment.apps/ping-pong-deployment created
service/ping-pong-svc created
ingress.networking.k8s.io/ping-pong-ingress created
➜ k get pods
NAME                                    READY   STATUS         RESTARTS   AGE
ping-pong-deployment-6b5ff4bbbd-kwbmb   0/1     ErrImagePull   0          38s
➜ k logs -f ping-pong-deployment-6b5ff4bbbd-kwbmb
Error from server (BadRequest): container "pingpong" in pod "ping-pong-deployment-6b5ff4bbbd-kwbmb" is waiting to start: trying and failing to pull image
```

Add a docker registry secret to the deployment manifest.

```bash
k create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=pjmartin \
  --docker-password=MyPAT \
  --docker-email=<my@email.com> \
  -n exercises
secret/regcred created

➜ k get secrets regcred -o yaml
apiVersion: v1
data:
  .dockerconfigjson: <MyBase64EncodedDockerConfig>
kind: Secret
metadata:
  creationTimestamp: "2025-09-08T08:15:44Z"
  name: regcred
  namespace: exercises
  resourceVersion: "30561"
  uid: 1fd8020e-532a-41b4-9ff2-2b0458641a8e
type: kubernetes.io/dockerconfigjson

➜ echo "<MyBase64EncodedDockerConfig>" | base64 --decode
{"auths":{"https://index.docker.io/v1/":{"username":"pjmartin","password":"MyPAT","email":"<my@email.com>","auth":"<myBase64EncodedAuth>"}}}
```

Seems i have missed to build x86_64 image. Build and push it to docker hub.

```bash
  Normal   Pulling    10s (x2 over 27s)  kubelet            Pulling image "docker.io/pjmartin/pingpong:3.1@sha256:f4c4760b32123fee8a16259044015923eee9c6e0b029cd9ab6fdf8e6b4ac09e1"
  Warning  Failed     8s (x2 over 25s)   kubelet            Failed to pull image "docker.io/pjmartin/pingpong:3.1@sha256:f4c4760b32123fee8a16259044015923eee9c6e0b029cd9ab6fdf8e6b4ac09e1": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/pjmartin/pingpong@sha256:f4c4760b32123fee8a16259044015923eee9c6e0b029cd9ab6fdf8e6b4ac09e1": no match for platform in manifest: not found
  Warning  Failed     8s (x2 over 25s)   kubelet            Error: ErrImagePull
```

My docker images were built for my local Arm64 M1 mac. I need to build for linux/amd64. So i updated the `./script/build-and-push.sh` script to use buildx and build for multiple platforms.

```bash
./script/build-and-push.sh 3.1
....
=== Log Output ===
arm64: docker.io/pjmartin/todo-app:3.1@sha256:ee93cba07a0c1cf1558b090eb0f97f8a6e2ba370dc857cec2d53950c179282e8
arm64: docker.io/pjmartin/pingpong:3.1@sha256:633f80a0b884708c0ef64e9ddebef032e47b3a781eac5c5cfb6cfba53d87f3ec
arm64: docker.io/pjmartin/log-reader:3.1@sha256:342c2cd3d47cf81a5b2c7b4f59ea79207785669e895ecfe64b51dcd1dffca078
arm64: docker.io/pjmartin/log-writer:3.1@sha256:eab3fe1c8829d21b7124139dacd2cbe163cb3eb7672d2d3617cbabae2db0ac5e
arm64: docker.io/pjmartin/todo-backend:3.1@sha256:dee0334cc0de64ccabd2a135df794225299052db9c827218e0790bda1b8044da
x86_64: docker.io/pjmartin/todo-app:3.1@sha256:c3001c69fbe7b57dd814ced1fd3c5dfb48df33309926f9de16c822c40f87b886
x86_64: docker.io/pjmartin/pingpong:3.1@sha256:ad21bf3ec6916a88f0bb7f03cf6fd27e85d347437c7c56ecb98f91ffa015f2c9
x86_64: docker.io/pjmartin/log-reader:3.1@sha256:3fd3fcbb749acfe030004ff33d8c01feee671f2cc3e30a5ec2cb5fd902c69ddb
x86_64: docker.io/pjmartin/log-writer:3.1@sha256:bdd18ca3cccb288a7f7532d26876e4874fa771f00fc8e37d7fbf32e1b95a0243
x86_64: docker.io/pjmartin/todo-backend:3.1@sha256:cd7c89eb4a6e210f4af4f30f242651b4180fab16bcc57682f71c9e65c1682f75

Multi-architecture build complete!
Images built for: linux/amd64, linux/arm64
These images will work on both ARM64 (local) and x86_64 (AKS) systems.
```

```bash
➜ ./script/postgres.sh apply
Applying postgres resources to namespace database...
Error from server (AlreadyExists): namespaces "database" already exists
secret/postgres-secrets created
service/postgres-svc created
statefulset.apps/postgres-stset created

➜ ./script/ping-pong.sh apply
Applying resources to namespace exercises...
Error from server (AlreadyExists): namespaces "exercises" already exists
secret/ping-pong-secrets created
configmap/log-output-config created
deployment.apps/ping-pong-deployment created
service/ping-pong-svc created
ingress.networking.k8s.io/ping-pong-ingress created

➜ k get pods -n exercises
NAME                                    READY   STATUS    RESTARTS   AGE
ping-pong-deployment-688648f568-h2vp2   1/1     Running   0          25s

➜ k logs -n exercises -f ping-pong-deployment-688648f568-h2vp2
INFO:     Started server process [7]
INFO:     Waiting for application startup.
2025-09-08 09:33:21,065 INFO File logging enabled to /app/data/logs/ping-pong-app.log
2025-09-08 09:33:21,065 INFO Attempting to connect to database: postgresql://postgres:***@postgres-svc.database:5432/postgres
2025-09-08 09:33:21,452 INFO Connected to database postgresql://postgres:********@postgres-svc.database:5432/postgres
2025-09-08 09:33:21,452 INFO Connected to PostgreSQL database
2025-09-08 09:33:21,457 INFO Database connectivity test successful: 1
2025-09-08 09:33:21,466 INFO Ping-pong table created or already exists
2025-09-08 09:33:21,469 INFO Current records in ping_pong table: 0
2025-09-08 09:33:21,475 INFO Initialized ping-pong counter in database with value 0
2025-09-08 09:33:21,475 INFO Database initialization successful - using PostgreSQL
2025-09-08 09:33:21,475 INFO Ping-pong server started on port 3000
2025-09-08 09:33:21,475 INFO App instance hash: cJi6hm
2025-09-08 09:33:21,475 INFO Storage mode: PostgreSQL
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
^C%

➜ k get ingress
NAME                CLASS    HOSTS   ADDRESS   PORTS   AGE
ping-pong-ingress   <none>   *                 80      41s

➜ k get svc
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
ping-pong-svc   ClusterIP   10.0.166.78   <none>        2345/TCP   2m19s
```

Now everything is up and running but i forgot to change the SVC type to LoadBalancer. I will redeploy the pingpong app with LoadBalancer type.

```bash
➜ ./script/ping-pong.sh apply
Applying resources to namespace exercises...
Error from server (AlreadyExists): namespaces "exercises" already exists
secret/ping-pong-secrets unchanged
configmap/log-output-config unchanged
deployment.apps/ping-pong-deployment unchanged
service/ping-pong-svc configured
ingress.networking.k8s.io/ping-pong-ingress unchanged

➜ k get svc --watch
NAME            TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
ping-pong-svc   LoadBalancer   10.0.166.78   <pending>     80:32340/TCP   4m4s
ping-pong-svc   LoadBalancer   10.0.166.78   135.225.2.178   80:32340/TCP   4m5s
```

Now i can access the ping pong application using the external IP.

```bash
➜ curl http://135.225.2.178/pingpong
{"message":"pong 0","counter":0,"storage":"database"}%
➜ curl http://135.225.2.178/pingpong
{"message":"pong 1","counter":1,"storage":"database"}%
```

