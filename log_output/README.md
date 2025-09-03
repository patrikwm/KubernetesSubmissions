
# Chapter 3


## Table of Contents

## 2.3. Keep them separated

Create namespace

```bash
➜ k create namespace exercises
namespace/exercises created
```

- In previous exercise i deleted the log_output app because of path collission. Now i change path to /logs so they can run parallel.


Deploy the applications to new namespace. Verify PVC is deployed to correct namespace.

```bash
➜ kubens default
Context "k3d-k3s-default" modified.
Active namespace is "default".
➜ k get persistentvolumeclaims
No resources found in default namespace.

➜ kubens exercises
Context "k3d-k3s-default" modified.
Active namespace is "exercises".

➜ k get persistentvolumeclaims
NAME                    STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS        VOLUMEATTRIBUTESCLASS   AGE
shared-volume-claim-0   Bound    agent-0-pv   1Gi        RWO            shared-agent-0-pv   <unset>                 58s
```

deploy apps to namespace

```bash
➜ k apply -f log_output/manifests -f ping-pong_application/manifests -n exercises --validate='strict'
deployment.apps/log-output-deployment created
ingress.networking.k8s.io/log-output-ingress created
service/log-output-svc created
deployment.apps/ping-pong-deployment created
ingress.networking.k8s.io/ping-pong-ingress created
service/ping-pong-svc created

➜ k get deployments.apps
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
log-output-deployment   1/1     1            1           7s
ping-pong-deployment    1/1     1            1           7s

➜ k get pods
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-85bf5f5f5b-5zwmg   2/2     Running   0          10s
ping-pong-deployment-78b976966c-n9jhs    1/1     Running   0          10s
```

Test application

```bash
➜ curl localhost:8081/logs
HTTP Server ID: 68a01156-b53e-4539-8cf9-40a1f15269ef
<br>Ping / Pongs: 0
</br></br>2025-09-03 11:42:16,982 - INFO - Server started with hash Wa07GQUfGY
<br>2025-09-03 11:42:16,982 - INFO - server id: Wa07GQUfGY - hash: Z1mBtREl2p
<br>2025-09-03 11:43:07,229 - INFO - Server started with hash 7EHahLi0Ni
<br>2025-09-03 11:43:07,229 - INFO - server id: 7EHahLi0Ni - hash: qbY9Pd2VPp
<br>2025-09-03 11:43:12,230 - INFO - server id: 7EHahLi0Ni - hash: jGWvVq6kA6
<br>2025-09-03 11:43:17,234 - INFO - server id: 7EHahLi0Ni - hash: QgSsDYDuIX
<br>%

➜ curl localhost:8081/pingpong
{"counter":0,"message":"pong 0"}

➜ curl localhost:8081/pingpong
{"counter":1,"message":"pong 1"}

➜ curl localhost:8081/logs
HTTP Server ID: 68a01156-b53e-4539-8cf9-40a1f15269ef
<br>Ping / Pongs: 2
</br></br>2025-09-03 11:47:22,358 - INFO - server id: 7EHahLi0Ni - hash: ejzZAsh7z2
<br>2025-09-03 11:47:27,362 - INFO - server id: 7EHahLi0Ni - hash: 2Kr3TCjCo6
<br>2025-09-03 11:47:32,363 - INFO - server id: 7EHahLi0Ni - hash: kqCEjpiggX
<br>2025-09-03 11:47:37,364 - INFO - server id: 7EHahLi0Ni - hash: h8cCWcIznQ
<br>2025-09-03 11:47:42,366 - INFO - server id: 7EHahLi0Ni - hash: LlcmI1oT1z
<br>2025-09-03 11:47:47,368 - INFO - server id: 7EHahLi0Ni - hash: 0hF7C3Usw6
<br>2025-09-03 11:47:52,369 - INFO - server id: 7EHahLi0Ni - hash: fpOtdqKtpf
<br>2025-09-03 11:47:57,370 - INFO - server id: 7EHahLi0Ni - hash: olTmjiqlvn
<br>2025-09-03 11:48:02,373 - INFO - server id: 7EHahLi0Ni - hash: 8HukY1tq1b
<br>2025-09-03 11:48:07,374 - INFO - server id: 7EHahLi0Ni - hash: 7MbVuMsQg5
<br>%

```