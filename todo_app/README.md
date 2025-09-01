# Chapter 2

# 1.12. The project, step 5


## App logic

```bash
[Start] -> listen on "/"
   |
   v
GET "/"
   |
   +-- if /app/images/image.jpg missing -> download & write .ts
   |
   +-- read current image to base64 string.
   |
   +-- Download new image if .ts older than 10 minutes -> download & write .ts
   |
   v
  return HTML with base64 image embedded
```

## Start with clean state

```bash
➜ k get deployments.apps
No resources found in default namespace.
```

## Delete old files in shared volume

```bash
➜ docker exec -ti k3d-k3s-default-agent-0 /bin/sh
~ # rm -rf /tmp/kube/*
~ # ls -al /tmp/kube
total 8
drwxr-xr-x 2 root root 4096 Sep  1 13:48 .
drwxrwxrwt 1 root root 4096 Sep  1 09:28 ..
```

## deploy application

```bash
➜ k apply -f todo_app/manifests
deployment.apps/todo-app-deployment created
ingress.networking.k8s.io/todo-app-ingress created
service/todo-app-svc created
```

## Verify deployment is up.

```bash
➜ k get deployments.apps
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
todo-app-deployment   1/1     1            1           14s
```

## Verify app downloads image and stores in shared volume

```bash
➜ docker exec k3d-k3s-default-agent-0 ls -al /tmp/kube/images
total 148
drwxr-xr-x 2 root root   4096 Sep  1 14:01 .
drwxr-xr-x 3 root root   4096 Sep  1 14:01 ..
-rw-r--r-- 1 root root     32 Sep  1 14:01 .ts
-rw-r--r-- 1 root root 135224 Sep  1 14:01 image.jpg
```

## Check timestamp file.

```bash
➜ docker exec k3d-k3s-default-agent-0 cat /tmp/kube/images/.ts
2025-09-01T13:56:44.775508+00:00%
```

## Todo app logs

```bash
➜ k logs -f todo-app-deployment-6f5488d64c-zsk7x
2025-09-01 14:01:38,983 INFO File logging enabled to /app/logs/todo-app.log
2025-09-01 14:01:38,983 INFO Image doesn't exist, downloading new image
2025-09-01 14:01:38,983 INFO Downloading new image from https://picsum.photos/1200
2025-09-01 14:01:41,308 INFO Successfully downloaded and saved new image
2025-09-01 14:01:41,309 INFO Todo app server started on port 3000
 * Serving Flask app 'app'
 * Debug mode: off
2025-09-01 14:01:41,311 INFO WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:3000
 * Running on http://10.42.3.55:3000
2025-09-01 14:01:41,311 INFO Press CTRL+C to quit
```

## First request to app

```bash
2025-09-01 14:02:38,130 INFO Home endpoint accessed
2025-09-01 14:02:38,130 INFO Image age: 56.822579, timeout: 600
2025-09-01 14:02:38,130 INFO 10.42.3.3 - - [01/Sep/2025 14:02:38] "GET / HTTP/1.1" 200 -
```

## 10+ min request to app

```bash
2025-09-01 14:12:18,389 INFO Home endpoint accessed
2025-09-01 14:12:18,389 INFO Image is stale (age: 637.081762 seconds), refreshing
2025-09-01 14:12:18,390 INFO Downloading new image from https://picsum.photos/1200
2025-09-01 14:12:19,326 INFO Successfully downloaded and saved new image
2025-09-01 14:12:19,327 INFO 10.42.3.3 - - [01/Sep/2025 14:12:19] "GET / HTTP/1.1" 200 -
2025-09-01 14:12:28,817 INFO Home endpoint accessed
2025-09-01 14:12:28,818 INFO Image age: 9.491279, timeout: 600
2025-09-01 14:12:28,818 INFO 10.42.3.3 - - [01/Sep/2025 14:12:28] "GET / HTTP/1.1" 200 -
```

## Force shutdown application

```bash
➜ curl http://localhost:8081/_shutdown
Bad Gateway%
```

## Get logs from respawned pod

```bash
➜ k logs -f todo-app-deployment-6f5488d64c-zsk7x
2025-09-01 14:19:50,318 INFO File logging enabled to /app/logs/todo-app.log
2025-09-01 14:19:50,318 INFO Todo app server started on port 3000
 * Serving Flask app 'app'
 * Debug mode: off
2025-09-01 14:19:50,319 INFO WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:3000
 * Running on http://10.42.3.55:3000
2025-09-01 14:19:50,319 INFO Press CTRL+C to quit
```

## Verify image still exists with Image age.

Visit website again and it will still show the same image.

```bash
2025-09-01 14:19:50,319 INFO Press CTRL+C to quit
2025-09-01 14:21:09,429 INFO Home endpoint accessed
2025-09-01 14:21:09,430 INFO Image age: 530.103222, timeout: 600
2025-09-01 14:21:09,430 INFO 10.42.3.3 - - [01/Sep/2025 14:21:09] "GET / HTTP/1.1" 200 -
````
