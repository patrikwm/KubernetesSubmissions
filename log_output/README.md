
# Chapter 2


## Table of Contents

## 2.1. Connecting pods


### Shut down todo_app

```bash
➜ k delete -f todo_app/manifests
deployment.apps "todo-app-deployment" deleted
ingress.networking.k8s.io "todo-app-ingress" deleted
service "todo-app-svc" deleted
```

### Deploy new ping-pong and todo_app

```bash
➜ k apply -f ping-pong_application/manifests -f log_output/manifests
deployment.apps/ping-pong-deployment created
ingress.networking.k8s.io/ping-pong-ingress created
service/ping-pong-svc created
deployment.apps/log-output-deployment created
ingress.networking.k8s.io/log-output-ingress created
service/log-output-svc created
```

### Test ping-pong service and log-output service

FIRT CALL 0 pings

```bash
➜ curl localhost:8081/
HTTP Server ID: 2a536b97-3be0-42f6-8652-f5c9639ea28c
Ping / Pongs: 0
</br></br>Could not find logfile log_output.log%
```

Increase pingcounter by calling pingpong endpoint two times.

```bash
➜ curl localhost:8081/pingpong.
{"counter":0,"message":"pong 0"}
➜ curl localhost:8081/pingpong
{"counter":1,"message":"pong 1"}
➜ curl localhost:8081/
```

Verify the counter increased two times and do not increase when calling log-output endpoint.

```bash
HTTP Server ID: 2a536b97-3be0-42f6-8652-f5c9639ea28c
Ping / Pongs: 2
</br></br>Could not find logfile log_output log%
➜ curl localhost:8081/
HTTP Server ID: 2a536b97-3be0-42f6-8652-f5c9639ea28c
Ping / Pongs: 2
</br></br>Could not find logfile log_output.log%
```