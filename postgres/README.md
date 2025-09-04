# Chapter 3 - Exercise: 2.7. Stateful applications

Create database namespace, deploy postgres using the manifest in `postgres/manifests/postgres.yaml`

```bash
➜ k create namespace database
namespace/database created
➜ kubens database
Context "k3d-k3s-default" modified.
Active namespace is "database".
➜ sops --decrypt postgres/manifests/secrets.enc.yaml | k apply -f -
secret/postgres-secrets created
➜ k apply -f postgres/manifests/postgres.yaml
service/postgres-svc created
statefulset.apps/postgres-stset created
```

check that the pod is running and accepting connections.

```bash
➜ k get statefulsets.apps
NAME             READY   AGE
postgres-stset   0/1     5s
➜ k logs -f postgres-stset-0
Error from server (BadRequest): container "postgres" in pod "postgres-stset-0" is waiting to start: ContainerCreating
➜ k get events
LAST SEEN   TYPE     REASON                  OBJECT                                                         MESSAGE
24s         Normal   WaitForFirstConsumer    persistentvolumeclaim/postgres-data-storage-postgres-stset-0   waiting for first consumer to be created before binding
24s         Normal   ExternalProvisioning    persistentvolumeclaim/postgres-data-storage-postgres-stset-0   Waiting for a volume to be created either by the external provisioner 'rancher.io/local-path' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
24s         Normal   Provisioning            persistentvolumeclaim/postgres-data-storage-postgres-stset-0   External provisioner is provisioning volume for claim "database/postgres-data-storage-postgres-stset-0"
22s         Normal   ProvisioningSucceeded   persistentvolumeclaim/postgres-data-storage-postgres-stset-0   Successfully provisioned volume pvc-628fa27f-4378-43e1-b86d-14d7d4ccbb10
21s         Normal   Scheduled               pod/postgres-stset-0                                           Successfully assigned database/postgres-stset-0 to k3d-k3s-default-server-0
20s         Normal   Pulling                 pod/postgres-stset-0                                           Pulling image "postgres:17.6"
12s         Normal   Pulled                  pod/postgres-stset-0                                           Successfully pulled image "postgres:17.6" in 8.497s (8.497s including waiting). Image size: 160049290 bytes.
12s         Normal   Created                 pod/postgres-stset-0                                           Created container postgres
12s         Normal   Started                 pod/postgres-stset-0                                           Started container postgres
24s         Normal   SuccessfulCreate        statefulset/postgres-stset                                     create Claim postgres-data-storage-postgres-stset-0 Pod postgres-stset-0 in StatefulSet postgres-stset success
24s         Normal   SuccessfulCreate        statefulset/postgres-stset                                     create Pod postgres-stset-0 in StatefulSet postgres-stset successful
```

Check logs of the postgres pod:

```bash
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
initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.
syncing data to disk ... ok


Success. You can now start the database server using:

    pg_ctl -D /var/lib/postgresql/data -l logfile start

waiting for server to start....2025-09-04 13:01:39.583 UTC [48] LOG:  starting PostgreSQL 17.6 (Debian 17.6-1.pgdg13+1) on aarch64-unknown-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
2025-09-04 13:01:39.584 UTC [48] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2025-09-04 13:01:39.586 UTC [51] LOG:  database system was shut down at 2025-09-04 13:01:39 UTC
2025-09-04 13:01:39.588 UTC [48] LOG:  database system is ready to accept connections
 done
server started

/usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*

waiting for server to shut down....2025-09-04 13:01:39.700 UTC [48] LOG:  received fast shutdown request
2025-09-04 13:01:39.702 UTC [48] LOG:  aborting any active transactions
2025-09-04 13:01:39.703 UTC [48] LOG:  background worker "logical replication launcher" (PID 54) exited with exit code 1
2025-09-04 13:01:39.703 UTC [49] LOG:  shutting down
2025-09-04 13:01:39.704 UTC [49] LOG:  checkpoint starting: shutdown immediate
2025-09-04 13:01:39.707 UTC [49] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.001 s, sync=0.001 s, total=0.004 s; sync files=2, longest=0.001 s, average=0.001 s; distance=0 kB, estimate=0 kB; lsn=0/14ED7B8, redo lsn=0/14ED7B8
2025-09-04 13:01:39.709 UTC [48] LOG:  database system is shut down
 done
server stopped

PostgreSQL init process complete; ready for start up.

2025-09-04 13:01:39.813 UTC [1] LOG:  starting PostgreSQL 17.6 (Debian 17.6-1.pgdg13+1) on aarch64-unknown-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
2025-09-04 13:01:39.813 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2025-09-04 13:01:39.813 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2025-09-04 13:01:39.814 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2025-09-04 13:01:39.816 UTC [62] LOG:  database system was shut down at 2025-09-04 13:01:39 UTC
2025-09-04 13:01:39.818 UTC [1] LOG:  database system is ready to accept connections
^C%
```

Verify postgres is running and accepting connections:

```bash
# pg_isready -h 127.0.0.1 -p 5432 -U postgres
127.0.0.1:5432 - accepting connections
# psql -h postgres-svc -U postgres -d postgres -c "select 1"
Password for user postgres:
 ?column?
----------
        1
(1 row)

#
```

### Apply pingpong deployment

```bash
➜ kubens exercises
Context "k3d-k3s-default" modified.
Active namespace is "exercises".
```

```bash
➜ sops --decrypt ping-pong_application/manifests/secret.enc.yaml | k apply -f -
secret/ping-pong-secrets configured

➜ k apply -f ping-pong_application/manifests/deployment.yaml -f ping-pong_application/manifests/ingress.yaml -f ping-pong_application/manifests/service.yaml
configmap/log-output-config created
deployment.apps/ping-pong-deployment created
ingress.networking.k8s.io/ping-pong-ingress created
service/ping-pong-svc created
```

Verify the pingpong application
```bash
➜ curl localhost:8081/pingpong
{"message":"pong 0","counter":0,"storage":"database"}%
➜ curl localhost:8081/pingpong
{"message":"pong 1","counter":1,"storage":"database"}%
```