# Chapter 2

# 1.4 Todo app

```bash
➜ kubectl delete deployments.apps todo-app
deployment.apps "todo-app" deleted
➜ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-688c79c6df-6mvln   1/1     Running   0          88s
➜ kubectl apply -f manifests/deployment.yaml
deployment.apps/todo-app-deployment created
➜ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-688c79c6df-6mvln   1/1     Running   0          111s
todo-app-deployment-658f556c84-vg9xj     1/1     Running   0          17s
➜ kubectl logs -f todo-app-deployment-658f556c84-vg9xj
2025-08-27 14:59:52,668 - INFO - Server started in port 8080
 * Serving Flask app 'app'
 * Debug mode: off
2025-08-27 14:59:52,669 - INFO - WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:8080
 * Running on http://10.42.2.28:8080
2025-08-27 14:59:52,669 - INFO - Press CTRL+C to quit
^C%
```