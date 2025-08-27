# Chapter 2

# 1.3 Declarative approach

```bash
➜ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
log-output-7d7695489f-jr77c   1/1     Running   0          41m
todo-app-85546b7976-7gzn9     1/1     Running   0          21m
➜ kubectl delete deployments.apps log-output
deployment.apps "log-output" deleted
➜ kubectl get pod
NAME                          READY   STATUS        RESTARTS   AGE
log-output-7d7695489f-jr77c   1/1     Terminating   0          41m
todo-app-85546b7976-7gzn9     1/1     Running       0          22m
➜ kubectl get pod
NAME                        READY   STATUS    RESTARTS   AGE
todo-app-85546b7976-7gzn9   1/1     Running   0          22m
➜ kubectl apply -f manifests/deployment.yaml
deployment.apps/log-output-deployment created
➜ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-688c79c6df-xzn5n   1/1     Running   0          15s
todo-app-85546b7976-7gzn9                1/1     Running   0          23m
➜ kubectl logs -f log-output-deployment-688c79c6df-xzn5n
2025-08-27T14:30:07.604Z: - t9wOIOpG8V
2025-08-27T14:30:12.605Z: - 71OgRFJrbf
2025-08-27T14:30:17.610Z: - tIbH2xWBaC
2025-08-27T14:30:22.612Z: - PKPSkD7fMX
2025-08-27T14:30:27.616Z: - 8BuSLJDfKC
2025-08-27T14:30:32.619Z: - aXbjCKcTBY
^C%
```