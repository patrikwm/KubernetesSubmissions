# Chapter 2

# 1.6. The project, step 4

| ⚠️ **Note** |
|-------------|
| Since the cluster has been redeployed, you must redeploy the `deployment.yaml` before applying the `service.yaml`. |

```bash
➜ k apply -f manifests/deployment.yaml
deployment.apps/todo-app-deployment created
➜ k apply -f manifests/service.yaml
service/todo-app-svc created
➜ k get deployments.apps
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
hashresponse-dep      1/1     1            1           90m
todo-app-deployment   1/1     1            1           88s
➜ k get service
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes     ClusterIP   10.43.0.1       <none>        443/TCP          92m
todo-app-svc   NodePort    10.43.168.211   <none>        1234:30080/TCP   16s
➜ docker ps -a |grep 8082
f9b58a889da0   ghcr.io/k3d-io/k3d-proxy:5.8.3   "/bin/sh -c nginx-pr…"   2 hours ago   Up 2 hours   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp, 0.0.0.0:63496->6443/tcp, 0.0.0.0:8082->30080/tcp, [::]:8082->30080/tcp   k3d-k3s-default-serverlb
➜ curl localhost:8082
<strong>App instance hash:</strong> NptmnR<br><strong>User request hash:</strong> gm69dW
➜ todo_app ⚡( 10-exercise-16-the-project-step-4)                                                                                        3.10.13 2 hours ago
▶
```