# Exercise: 2.8. The project, step 11

Change namespace to "project"

```bash
➜ kubens project
Context "k3d-k3s-default" modified.
Active namespace is "project".
```

Apply secrets, configmap, and deployment manifests:

```bash
➜ sops --decrypt todo-backend/manifests/secrets.enc.yaml | k apply -f -
secret/todo-backend-secrets created
➜ k apply -f todo-backend/manifests/configmap.yaml -f todo-backend/manifests/deployment.yaml -f todo-backend/manifests/service.yaml
configmap/todo-backend-config configured
deployment.apps/todo-backend-deployment configured
service/todo-backend-svc unchanged
```

Verify app is running

```bash
➜ k get pods
NAME                                       READY   STATUS        RESTARTS   AGE
todo-app-deployment-d45b78496-2qczh        1/1     Running       0          5h51m
todo-backend-deployment-79c76b495-gzz87    1/1     Terminating   0          5h56m
todo-backend-deployment-84d6699855-bhhjn   1/1     Running       0          13s
➜ k logs -f todo-backend-deployment-84d6699855-bhhjn
INFO:     Started server process [7]
INFO:     Waiting for application startup.
2025-09-04 14:45:44,896 INFO Attempting to connect to database: postgresql://postgres:***@postgres-svc:5432/postgres
2025-09-04 14:45:44,905 ERROR Error initializing database: [Errno -2] Name or service not known
2025-09-04 14:45:44,905 ERROR Database URL (sanitized): postgresql://postgres:***@postgres-svc:5432/postgres
2025-09-04 14:45:44,905 WARNING Database initialization failed - falling back to in-memory storage: [Errno -2] Name or service not known
2025-09-04 14:45:44,905 INFO Todo-backend server started
2025-09-04 14:45:44,905 INFO Storage mode: In-memory
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
^C%
```

Posgres is not reachable since its running in database namespace. Need to update POSTGRES_HOST variable in configmap to `postgres-svc.database`

```bash
➜ cat todo-backend/manifests/configmap.yaml
───────┬──────────────────────────────────────────────────────────────
       │ File: todo-backend/manifests/configmap.yaml
───────┼──────────────────────────────────────────────────────────────
   1   │ apiVersion: v1
   2   │ kind: ConfigMap
   3   │ metadata:
   4   │   name: todo-backend-config
   5   │ data:
   6   │   PORT: "3000"
   7 ~ │   CORS_ORIGINS: "*"
   8 ~ │   POSTGRES_HOST: "postgres-svc.database"
   9 ~ │   POSTGRES_PORT: "5432"
  10 ~ │   POSTGRES_DB: "postgres"
  11 ~ │   POSTGRES_USER: "postgres"
───────┴──────────────────────────────────────────────────────────────
```

Reapply configmap and restart deployment

```bash
➜ k apply -f todo-backend/manifests/configmap.yaml
configmap/todo-backend-config configured
➜ k delete -f todo-backend/manifests/deployment.yaml && k apply -f todo-backend/manifests/deployment.yaml
deployment.apps "todo-backend-deployment" deleted
deployment.apps/todo-backend-deployment created
````

```bash
➜ k logs -f todo-backend-deployment-84d6699855-8tlmg
INFO:     Started server process [7]
INFO:     Waiting for application startup.
2025-09-04 14:48:49,903 INFO Attempting to connect to database: postgresql://postgres:***@postgres-svc.database:5432/postgres
2025-09-04 14:48:50,058 INFO Connected to database postgresql://postgres:********@postgres-svc.database:5432/postgres
2025-09-04 14:48:50,058 INFO Connected to PostgreSQL database
2025-09-04 14:48:50,058 INFO Database connectivity test successful: 1
2025-09-04 14:48:50,061 INFO Todos table created or already exists
2025-09-04 14:48:50,062 INFO Current records in todos table: 0
2025-09-04 14:48:50,062 INFO Database initialization successful - using PostgreSQL
2025-09-04 14:48:50,062 INFO Todo-backend server started
2025-09-04 14:48:50,062 INFO Storage mode: PostgreSQL
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
```

Manually added a todo in Webbrowser. Now it appears in curl output.

```bash
➜ curl localhost:8081/

    <h1>The project App</h1>
    <img src="/image?ver=2025-09-04T14:49:40.575032+00:00" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>
      <li>⬜️ Buy new cables to TS50x</li>
    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
    %
```

Verify database content

```bash
➜ k exec -ti -n database postgres-stset-0 -- sh
# psql -U postgres -d postgres
psql (17.6 (Debian 17.6-1.pgdg13+1))
Type "help" for help.

postgres=# \l
                                                    List of databases
   Name    |  Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | Locale | ICU Rules |   Access privileges
-----------+----------+----------+-----------------+------------+------------+--------+-----------+-----------------------
 postgres  | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           |
 template0 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +
           |          |          |                 |            |            |        |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |        |           | =c/postgres          +
           |          |          |                 |            |            |        |           | postgres=CTc/postgres
(3 rows)

postgres=# \c postgres
You are now connected to database "postgres" as user "postgres".
postgres=# \dt
           List of relations
 Schema |   Name    | Type  |  Owner
--------+-----------+-------+----------
 public | ping_pong | table | postgres
 public | todos     | table | postgres
(2 rows)

postgres=# select * from todos;
                  id                  |          text           | done |          created_at
--------------------------------------+-------------------------+------+-------------------------------
 8dd756e0-195b-4a3d-8db6-0d6f66321f67 | Buy new cables to TS50x | f    | 2025-09-04 14:49:58.935036+00
(1 row)

postgres=#
```