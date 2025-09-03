# Chapter 3

## Exercise: 2.2. The project, step 8

Moved from FLASK to FastAPI to get better performance and async support for image fetching.

### Clean up log_output

Remove log_output since i have set todo app and log output app to use same port / path.
I could have changed the ports to have the apps parallell, but this is simpler.

```bash
k delete -f log_output/manifests -f ping-pong_application/manifests
deployment.apps "log-output-deployment" deleted
ingress.networking.k8s.io "log-output-ingress" deleted
service "log-output-svc" deleted
deployment.apps "ping-pong-deployment" deleted
ingress.networking.k8s.io "ping-pong-ingress" deleted
service "ping-pong-svc" deleted
```

### Deploy todo-app

```bash
➜ k apply -f todo-app/manifests
deployment.apps/todo-app-deployment created
ingress.networking.k8s.io/todo-app-ingress created
service/todo-app-svc created
```

### Get todos

Currently i return static todos if backend is not reachable.

```bash
➜ curl localhost:8081/

    <h1>The project App</h1>
    <img src="/image?ver=2025-09-03T09:07:10.997349+00:00" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>
      <li>⬜️ Learn JavaScript</li><li>⬜️ Learn React</li><li>✅ Build a project</li>
    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
    %
```

### Deploy todo-backend

```bash
➜ k apply -f todo-backend/manifests
deployment.apps/todo-backend-deployment created
service/todo-backend-svc created
```

### Verify todos from backend

```bash
➜ curl localhost:8081/

    <h1>The project App</h1>
    <img src="/image?ver=2025-09-03T09:07:10.997349+00:00" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>

    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
```

### Create todo

```bash
➜ curl -i -L \
  -X POST 'http://localhost:8081/' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'todo=Buy milk'
HTTP/1.1 303 See Other
Content-Length: 0
Date: Wed, 03 Sep 2025 09:26:04 GMT
Location: /
Server: uvicorn

HTTP/1.1 422 Unprocessable Entity
Content-Length: 89
Content-Type: application/json
Date: Wed, 03 Sep 2025 09:26:04 GMT
Server: uvicorn

{"detail":[{"type":"missing","loc":["body","todo"],"msg":"Field required","input":null}]}%
```

### Verify todo is created

First task is now created.

```bash
curl localhost:8081/

    <h1>The project App</h1>
    <img src="/image?ver=2025-09-03T09:19:10.515162+00:00" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>
      <li>⬜️ Buy milk</li>
    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
    %
```

### Verify todo-app logs

1. Todos backend is failing on request at 09:23:16,466
2. Backend is started and reachable at 09:23:36,994

```bash
➜ k logs todo-app-deployment-6bdd5c6df4-7kg5h
INFO:     Started server process [1]
INFO:     Waiting for application startup.
2025-09-03 09:23:05,820 INFO File logging -> /app/data/logs/todo-app.log
2025-09-03 09:23:05,821 INFO todo-app started
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
2025-09-03 09:23:16,466 WARNING Backend /todos failed: [Errno -2] Name or service not known
INFO:     10.42.3.3:49308 - "GET / HTTP/1.1" 200 OK
2025-09-03 09:23:36,994 INFO HTTP Request: GET http://todo-backend-svc:2345/todos "HTTP/1.1 200 OK"
INFO:     10.42.3.3:37506 - "GET / HTTP/1.1" 200 OK
2025-09-03 09:26:04,567 INFO HTTP Request: POST http://todo-backend-svc:2345/todos "HTTP/1.1 201 Created"
INFO:     10.42.3.3:43556 - "POST / HTTP/1.1" 303 See Other
INFO:     10.42.3.3:43556 - "POST / HTTP/1.1" 422 Unprocessable Entity
2025-09-03 09:26:13,314 INFO HTTP Request: GET http://todo-backend-svc:2345/todos "HTTP/1.1 200 OK"
INFO:     10.42.3.3:33052 - "GET / HTTP/1.1" 200 OK
```

3. Traffic is originating from IP 10.42.3.3 which is the Traefik proxy pod running on the same node as the todo-app.

```bash
➜ k get pods -A -o wide | grep '10.42.3.3'
kube-system   traefik-5d45fc8cc9-dr5q4                   1/1     Running     0          6d      10.42.3.3    k3d-k3s-default-agent-0    <none>           <none>
```

### Verify todo-backend logs

All requests are coming from 10.42.3.80 which is the todo-app pod.

```bash
➜ k logs todo-backend-deployment-7ddbc458dc-ptlf6
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
INFO:     10.42.3.80:34298 - "GET /todos HTTP/1.1" 200 OK
INFO:     10.42.3.80:45886 - "POST /todos HTTP/1.1" 201 Created
INFO:     10.42.3.80:39590 - "GET /todos HTTP/1.1" 200 OK
```

check IP of todo-app pod

```bash
➜ k get pods -A -o wide |grep '10.42.3.80'
default       todo-app-deployment-6bdd5c6df4-7kg5h       1/1     Running     0          12m   10.42.3.80   k3d-k3s-default-agent-0    <none>           <none>
```