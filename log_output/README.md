
# Chapter 2


## Table of Contents

- [1.10. Even more services](#110-even-more-services)
	- [Create a shared Persistent Volume](#create-a-shared-persistent-volume)
	- [Mount PVC to log reader and writer applications](#mount-pvc-to-log-reader-and-writer-applications)
	- [change persistentVolumeClaim.name to persistentVolumeClaim.claimName](#change-persistentvolumeclaimname-to-persistentvolumeclaimclaimname)
	- [Mount PVC to Pingpong application](#mount-pvc-to-pingpong-application)
	- [Update Todo app path](#update-todo-app-path)
	- [Verify everything is working](#verify-everything-is-working)


## 1.10. Even more services


### Create a shared Persistent Volume

```bash
➜ k apply -f manifests/infra/agent-0
persistentvolume/agent-0-pv created
persistentvolumeclaim/shared-volume-claim-0 created

➜ k get persistentvolume
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS        VOLUMEATTRIBUTESCLASS   REASON   AGE
agent-0-pv   1Gi        RWO            Retain           Bound    default/shared-volume-claim-0   shared-agent-0-pv   <unset>                          8s

➜ k get persistentvolumeclaims
NAME                    STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS        VOLUMEATTRIBUTESCLASS   AGE
shared-volume-claim-0   Bound    agent-0-pv   1Gi        RWO            shared-agent-0-pv   <unset>                 9s
```

### Mount PVC to log reader and writer applications

```bash
➜ k apply -f log_output/manifests/deployment.yaml
The request is invalid: patch: Invalid value: "map[metadata:map[annotations:map[kubectl.kubernetes.io/last-applied-configuration:{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"name\":\"log-output-deployment\",\"namespace\":\"default\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"logoutput\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"logoutput\"}},\"spec\":{\"containers\":[{\"env\":[{\"name\":\"LOG_FILE\",\"value\":\"/app/logs/log_output.log\"}],\"image\":\"pjmartin/log-reader:1.10.1\",\"imagePullPolicy\":\"Always\",\"name\":\"log-reader\",\"ports\":[{\"containerPort\":3000,\"name\":\"http\"}],\"volumeMounts\":[{\"mountPath\":\"/app/logs\",\"name\":\"log-output\"}]},{\"env\":[{\"name\":\"LOG_FILE\",\"value\":\"/app/logs/log_output.log\"}],\"image\":\"pjmartin/log-writer:1.10\",\"imagePullPolicy\":\"Always\",\"name\":\"log-writer\",\"volumeMounts\":[{\"mountPath\":\"/app/logs\",\"name\":\"log-output\"}]}],\"volumes\":[{\"name\":\"log-output\",\"persistentVolumeClaim\":{\"name\":\"shared-volume-claim-0\"}}]}}}}\n]] spec:map[templ

➜ k apply -f log_output/manifests/deployment.yaml --validate=true
The request is invalid: patch: Invalid value: "map[metadata:map[annotations:map[kubectl.kubernetes.io/last-applied-configuration:{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"metadata\":{\"annotations\":{},\"name\":\"log-output-deployment\",\"namespace\":\"default\"},\"spec\":{\"replicas\":1,\"selector\":{\"matchLabels\":{\"app\":\"logoutput\"}},\"template\":{\"metadata\":{\"labels\":{\"app\":\"logoutput\"}},\"spec\":{\"containers\":[{\"env\":[{\"name\":\"LOG_FILE\",\"value\":\"/app/logs/log_output.log\"}],\"image\":\"pjmartin/log-reader:1.10.1\",\"imagePullPolicy\":\"Always\",\"name\":\"log-reader\",\"ports\":[{\"containerPort\":3000,\"name\":\"http\"}],\"volumeMounts\":[{\"mountPath\":\"/app/logs\",\"name\":\"log-output\"}]},{\"env\":[{\"name\":\"LOG_FILE\",\"value\":\"/app/logs/log_output.log\"}],\"image\":\"pjmartin/log-writer:1.10\",\"imagePullPolicy\":\"Always\",\"name\":\"log-writer\",\"volumeMounts\":[{\"mountPath\":\"/app/logs\",\"name\":\"log-output\"}]}],\"volumes\":[{\"name\":\"log-output\",\"persistentVolumeClaim\":{\"name\":\"shared-volume-claim-0\"}}]}}}}\n]] spec:map[template:map[spec:map[]]]]": strict decoding error: unknown field "spec.template.spec.volumes[0].persistentVolumeClaim.name"
```

## change persistentVolumeClaim.name to persistentVolumeClaim.claimName

```bash
➜ k apply -f log_output/manifests/deployment.yaml

➜ curl localhost:8081/
<h1>HTTP Server ID: 0C38FTMZYo</h1><br>2025-08-29 15:50:53,076 - INFO - Server started with hash 7q6dYSHuVu
<br>2025-08-29 15:50:53,076 - INFO - server id: 7q6dYSHuVu - hash: cAZ8OObIcc
<br>2025-08-29 15:50:58,086 - INFO - server id: 7q6dYSHuVu - hash: va1xo0it4j
<br>2025-08-29 15:51:03,089 - INFO - server id: 7q6dYSHuVu - hash: J5QQYYKDnt
<br>2025-08-29 15:51:08,099 - INFO - server id: 7q6dYSHuVu - hash: VSkJrtsOa7
<br>2025-08-29 15:51:13,105 - INFO - server id: 7q6dYSHuVu - hash: VHCmt2JqpP
<br>%

➜ docker exec k3d-k3s-default-agent-0 ls /tmp/kube
log_output.log

➜ docker exec k3d-k3s-default-agent-0 cat /tmp/kube/log_output.log
2025-08-29 15:50:53,076 - INFO - Server started with hash 7q6dYSHuVu
2025-08-29 15:50:53,076 - INFO - server id: 7q6dYSHuVu - hash: cAZ8OObIcc
2025-08-29 15:50:58,086 - INFO - server id: 7q6dYSHuVu - hash: va1xo0it4j
2025-08-29 15:51:03,089 - INFO - server id: 7q6dYSHuVu - hash: J5QQYYKDnt
2025-08-29 15:51:08,099 - INFO - server id: 7q6dYSHuVu - hash: VSkJrtsOa7
2025-08-29 15:51:13,105 - INFO - server id: 7q6dYSHuVu - hash: VHCmt2JqpP
2025-08-29 15:51:18,116 - INFO - server id: 7q6dYSHuVu - hash: Rq5zQabE7G
2025-08-29 15:51:23,123 - INFO - server id: 7q6dYSHuVu - hash: JYV2G5qYhK
2025-08-29 15:51:28,131 - INFO - server id: 7q6dYSHuVu - hash: C2fkY7LoWD
2025-08-29 15:51:33,142 - INFO - server id: 7q6dYSHuVu - hash: QcmoVsncPQ
2025-08-29 15:51:38,151 - INFO - server id: 7q6dYSHuVu - hash: D1U8xUwFXK
```

### Mount PVC to Pingpong application

```bash
➜ k apply -f ping-pong_application/manifests/deployment.yaml
deployment.apps/ping-pong-deployment configured
➜ k get pods
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-54495c9d9d-qfl2g   2/2     Running   0          11m
ping-pong-deployment-5574c9f7b7-k6rtn    1/1     Running   0          45s
todo-app-deployment-bd879fdf5-ltjtw      1/1     Running   0          29h
➜ k get deployments.apps ping-pong-deployment
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
ping-pong-deployment   1/1     1            1           27h
➜ k exec -ti ping-pong-deployment-5574c9f7b7-k6rtn -- sh
# ls /app/logs
log_output.log
```

### Update Todo app path

Todo app path is colliding with the log_output. I change the path to /todo and redeployed.

```bash
➜ docker build . --tag pjmartin/todo_app:1.11 --push
[+] Building 7.1s (12/12) FINISHED                                                                                           docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                         0.0s
 => => transferring dockerfile: 215B                                                                                                         0.0s
 => [internal] load metadata for docker.io/library/python:3.10.13-slim                                                                       1.0s
 => [auth] library/python:pull token for registry-1.docker.io                                                                                0.0s
 => [internal] load .dockerignore                                                                                                            0.0s
 => => transferring context: 2B                                                                                                              0.0s
 => [1/5] FROM docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922                 0.0s
 => => resolve docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922                 0.0s
 => [internal] load build context                                                                                                            0.1s
 => => transferring context: 199.89kB                                                                                                        0.1s
 => CACHED [2/5] WORKDIR /app                                                                                                                0.0s
 => CACHED [3/5] COPY requirements.txt requirements.txt                                                                                      0.0s
 => CACHED [4/5] RUN pip install -r requirements.txt                                                                                         0.0s
 => [5/5] COPY . .                                                                                                                           0.1s
 => exporting to image                                                                                                                       5.8s
 => => exporting layers                                                                                                                      0.7s
 => => exporting manifest sha256:a76c5043ed167b54be492e68d58a8c128d8c61f8282a3d1675f79530a3a58174                                            0.0s
 => => exporting config sha256:7c5c530e1cc9b34c6fa4ca1e5b27933ee3d8a3e17d367943c39cd06e0ad71840                                              0.0s
 => => exporting attestation manifest sha256:505c0d1687228b3a44c713d11a0758505ebe7af12a89311fc6626b1b99bedf3d                                0.0s
 => => exporting manifest list sha256:5aff0deac30f4c3e1eb05a97b761447a24e431f190b5e185e5e4698836cefda4                                       0.0s
 => => naming to docker.io/pjmartin/todo_app:1.11                                                                                            0.0s
 => => unpacking to docker.io/pjmartin/todo_app:1.11                                                                                         0.1s
 => => pushing layers                                                                                                                        2.6s
 => => pushing manifest for docker.io/pjmartin/todo_app:1.11@sha256:5aff0deac30f4c3e1eb05a97b761447a24e431f190b5e185e5e4698836cefda4         2.3s
 => [auth] pjmartin/todo_app:pull,push token for registry-1.docker.io                                                                        0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/61pihow3r4d2sa3cko2c0v91c

➜ k apply -f manifests
deployment.apps/todo-app-deployment configured
ingress.networking.k8s.io/todo-app-ingress unchanged
service/todo-app-svc unchanged
```

### Verify everything is working

```bash
➜ docker exec k3d-k3s-default-agent-0 ls /tmp/kube
log_output.log
ping-pong.log
➜ docker exec k3d-k3s-default-agent-0 cat /tmp/kube/ping-pong.log
2%
➜ curl localhost:8081/pingpong
pong 2%
➜ curl localhost:8081/
<h1>HTTP Server ID: L7GyACo74O</h1><br>Ping / Pongs: 3</br></br>2025-08-30 10:59:27,324 - INFO - server id: 4pJ1irCzU6 - hash: aOuadN9dyJ
<br>2025-08-30 10:59:32,331 - INFO - server id: 4pJ1irCzU6 - hash: mRy7VMykI4
<br>2025-08-30 10:59:37,333 - INFO - server id: 4pJ1irCzU6 - hash: 0bcGhvRmqG
<br>2025-08-30 10:59:42,340 - INFO - server id: 4pJ1irCzU6 - hash: AK51dqkQeE
<br>2025-08-30 10:59:47,347 - INFO - server id: 4pJ1irCzU6 - hash: sUDQRiYWBN
<br>2025-08-30 10:59:52,352 - INFO - server id: 4pJ1irCzU6 - hash: yu4VKJielP
<br>2025-08-30 10:59:57,361 - INFO - server id: 4pJ1irCzU6 - hash: 2Sftgv9F6f
<br>2025-08-30 11:00:02,362 - INFO - server id: 4pJ1irCzU6 - hash: y6JqZ2tMWr
<br>2025-08-30 11:00:07,370 - INFO - server id: 4pJ1irCzU6 - hash: eGQ3nFJ6WG
<br>2025-08-30 11:00:12,379 - INFO - server id: 4pJ1irCzU6 - hash: u8kTE37Qc0
<br>%
➜ docker exec k3d-k3s-default-agent-0 cat /tmp/kube/ping-pong.log
3%
```
