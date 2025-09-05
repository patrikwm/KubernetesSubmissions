# Chapter 4

# Exercise: 3.1. Pingpong AKS

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

Delete StatefulSet of Prometheus, Update the storage class to managed-csi, and redeploy.

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

Seems the image is not being pulled. I will try to change the image to be fully qualified and redeploy.

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

