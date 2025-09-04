# Chapter 3

## Exercise: 2.6. The project, step 10

Check if configmaps are deployed.

```bash
➜ k get configmaps
NAME                  DATA   AGE
kube-root-ca.crt      1      20h
todo-app-config       5      112s
todo-backend-config   2      112s
```

Check what port the todo-app is running on (should be 3000 now).

```bash

➜ k logs -f todo-app-deployment-d45b78496-vxrmg
INFO:     Started server process [7]
INFO:     Waiting for application startup.
2025-09-04 08:49:40,178 INFO File logging -> /app/data/logs/todo-app.log
2025-09-04 08:49:40,178 INFO todo-app started
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
^C%
```

change the port to 4000 in the configmap and redeploy the app.

```bash
➜ cat todo-app/manifests/configmap.yaml|grep PORT
  PORT: "4000"
➜ k apply -f todo-app/manifests/configmap.yaml
configmap/todo-app-config configured
➜ k delete -f todo-app/manifests/deployment.yaml
deployment.apps "todo-app-deployment" deleted
➜ k apply -f todo-app/manifests/deployment.yaml
deployment.apps/todo-app-deployment created
```

Verify the app now gets PORT from variable and is running on port 4000.

```bash
➜ k logs -f todo-app-deployment-d45b78496-5588t
INFO:     Started server process [7]
INFO:     Waiting for application startup.
2025-09-04 08:51:39,133 INFO File logging -> /app/data/logs/todo-app.log
2025-09-04 08:51:39,134 INFO todo-app started
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:4000 (Press CTRL+C to quit)
```

Reverted changes after verification.

```bash
➜ cat todo-app/manifests/configmap.yaml|grep PORT
  PORT: "3000"
➜ k apply -f todo-app/manifests/configmap.yaml
configmap/todo-app-config configured
➜ k delete -f todo-app/manifests/deployment.yaml
deployment.apps "todo-app-deployment" deleted
➜ k apply -f todo-app/manifests/deployment.yaml
deployment.apps/todo-app-deployment created
➜ k logs -f todo-app-deployment-d45b78496-2qczh
INFO:     Started server process [7]
INFO:     Waiting for application startup.
2025-09-04 08:54:38,595 INFO File logging -> /app/data/logs/todo-app.log
2025-09-04 08:54:38,595 INFO todo-app started
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:3000 (Press CTRL+C to quit)
```
