# Chapter 2

# 1.10. Even more services

```bash
➜ docker build -f Dockerfile.write --tag pjmartin/log-writer:1.10 --push .
[+] Building 5.7s (12/12) FINISHED                                                                             docker:desktop-linux
 => [internal] load build definition from Dockerfile.write                                                                     0.0s
 => => transferring dockerfile: 226B                                                                                           0.0s
 => [internal] load metadata for docker.io/library/python:3.10.13-slim                                                         1.0s
 => [auth] library/python:pull token for registry-1.docker.io                                                                  0.0s
 => [internal] load .dockerignore                                                                                              0.0s
 => => transferring context: 2B                                                                                                0.0s
 => [1/5] FROM docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922   0.0s
 => => resolve docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922   0.0s
 => [internal] load build context                                                                                              0.0s
 => => transferring context: 70B                                                                                               0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                  0.0s
 => CACHED [3/5] COPY requirements.txt requirements.txt                                                                        0.0s
 => CACHED [4/5] RUN pip install -r requirements.txt                                                                           0.0s
 => [5/5] COPY log-writer.py log-writer.py                                                                                     0.0s
 => exporting to image                                                                                                         4.6s
 => => exporting layers                                                                                                        0.0s
 => => exporting manifest sha256:921581573420d20b2be9f7d35c81aa5cbc2de8b050487688638e464533ef3b1f                              0.0s
 => => exporting config sha256:00e5b32aa1619cf194cda62af454b16e34051561c8adc829c25a2df26eb81cbb                                0.0s
 => => exporting attestation manifest sha256:8458162509c9d737388c63f6b38411820654703facc119a341bf06d28ef14bcb                  0.0s
 => => exporting manifest list sha256:da9bc4c3d7c0c124aef9ecd571b65b7adba2a26e8ee464dd2ba98311d459b32a                         0.0s
 => => naming to docker.io/pjmartin/log-writer:1.10                                                                            0.0s
 => => unpacking to docker.io/pjmartin/log-writer:1.10                                                                         0.0s
 => => pushing layers                                                                                                          2.0s
 => => pushing manifest for docker.io/pjmartin/log-writer:1.10@sha256:da9bc4c3d7c0c124aef9ecd571b65b7adba2a26e8ee464dd2ba9831  2.5s
 => [auth] pjmartin/log-writer:pull,push token for registry-1.docker.io                                                        0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/3xwjta75ols7anhyolberp2le
➜ docker build -f Dockerfile.read --tag pjmartin/log-reader:1.10 --push .
[+] Building 5.0s (11/11) FINISHED                                                                             docker:desktop-linux
 => [internal] load build definition from Dockerfile.read                                                                      0.0s
 => => transferring dockerfile: 237B                                                                                           0.0s
 => [internal] load metadata for docker.io/library/python:3.10.13-slim                                                         0.3s
 => [internal] load .dockerignore                                                                                              0.0s
 => => transferring context: 2B                                                                                                0.0s
 => [1/5] FROM docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922   0.0s
 => => resolve docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922   0.0s
 => [internal] load build context                                                                                              0.0s
 => => transferring context: 1.83kB                                                                                            0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                  0.0s
 => CACHED [3/5] COPY requirements.txt requirements.txt                                                                        0.0s
 => CACHED [4/5] RUN pip install -r requirements.txt                                                                           0.0s
 => [5/5] COPY log-reader.py log-reader.py                                                                                     0.0s
 => exporting to image                                                                                                         4.6s
 => => exporting layers                                                                                                        0.0s
 => => exporting manifest sha256:91602e5c58b7a36bb25a6e0907d6504d72668fc272447dfce91e7eba351f8312                              0.0s
 => => exporting config sha256:32c82c2d7af9b9c055a4dc8b06f4ce9af98349ecf75e9b1ab188f37228c5f4ba                                0.0s
 => => exporting attestation manifest sha256:0b70cea73f0b560c586ffead6d687ff757c9d8840b455ce9aa188d0ed457bd76                  0.0s
 => => exporting manifest list sha256:26b87b35c2aae1daad08c8fd129fed71a1b42359946db42393a24034b64868fd                         0.0s
 => => naming to docker.io/pjmartin/log-reader:1.10                                                                            0.0s
 => => unpacking to docker.io/pjmartin/log-reader:1.10                                                                         0.0s
 => => pushing layers                                                                                                          2.2s
 => => pushing manifest for docker.io/pjmartin/log-reader:1.10@sha256:26b87b35c2aae1daad08c8fd129fed71a1b42359946db42393a2403  2.3s
 => [auth] pjmartin/log-reader:pull,push token for registry-1.docker.io                                                        0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/llti4b0y5pfpjdfd2qr4mjqnv
➜ k apply -f manifests
deployment.apps/log-output-deployment configured
ingress.networking.k8s.io/log-output-ingress unchanged
service/log-output-svc configured
➜ k logs -f log-output-deployment-7576d8764b-lmtds
Defaulted container "log-reader" out of: log-reader, log-writer
2025-08-29 13:44:05,023 - INFO - Server started in port 3000
2025-08-29 13:44:05,023 - INFO - Initial random string: 4Q78EX6YIk
 * Serving Flask app 'log-reader'
 * Debug mode: off
2025-08-29 13:44:05,025 - INFO - WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:3000
 * Running on http://10.42.1.7:3000
2025-08-29 13:44:05,025 - INFO - Press CTRL+C to quit
2025-08-29 13:44:45,303 - INFO - 10.42.3.3 - - [29/Aug/2025 13:44:45] "GET / HTTP/1.1" 200 -
2025-08-29 13:44:56,397 - INFO - 10.42.3.3 - - [29/Aug/2025 13:44:56] "GET / HTTP/1.1" 200 -
2025-08-29 13:44:59,259 - INFO - 10.42.3.3 - - [29/Aug/2025 13:44:59] "GET / HTTP/1.1" 200 -
2025-08-29 13:45:01,122 - INFO - 10.42.3.3 - - [29/Aug/2025 13:45:01] "GET / HTTP/1.1" 200 -
2025-08-29 13:45:04,869 - INFO - 10.42.3.3 - - [29/Aug/2025 13:45:04] "GET / HTTP/1.1" 200 -
2025-08-29 13:45:05,937 - INFO - 10.42.3.3 - - [29/Aug/2025 13:45:05] "GET / HTTP/1.1" 200 -
^C%
➜ k get pods
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-7576d8764b-lmtds   2/2     Running   0          103s
ping-pong-deployment-8fc885847-bjvnt     1/1     Running   0          25h
todo-app-deployment-bd879fdf5-ltjtw      1/1     Running   0          26h
➜ k get pods log-output-deployment-7576d8764b-lmtds
NAME                                     READY   STATUS    RESTARTS   AGE
log-output-deployment-7576d8764b-lmtds   2/2     Running   0          106s
➜ k get pods log-output-deployment-7576d8764b-lmtds -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2025-08-29T13:43:59Z"
  generateName: log-output-deployment-7576d8764b-
  labels:
    app: logoutput
    pod-template-hash: 7576d8764b
  name: log-output-deployment-7576d8764b-lmtds
  namespace: default
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: log-output-deployment-7576d8764b
    uid: af8c040d-5b35-4d44-a36c-d30e32b795b5
  resourceVersion: "35101"
  uid: a948779f-f3f1-47f9-9aa8-d9fa732f8668
spec:
  containers:
  - env:
    - name: LOG_FILE
      value: /app/logs/log_output.log
    image: pjmartin/log-reader:1.10
    imagePullPolicy: Always
    name: log-reader
    ports:
    - containerPort: 3000
      name: http
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /app/logs
      name: log-output
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-slh7j
      readOnly: true
  - env:
    - name: LOG_FILE
      value: /app/logs/log_output.log
    image: pjmartin/log-writer:1.10
    imagePullPolicy: Always
    name: log-writer
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /app/logs
      name: log-output
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-slh7j
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k3d-k3s-default-agent-1
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - emptyDir:
      sizeLimit: 20Mi
    name: log-output
  - name: kube-api-access-slh7j
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2025-08-29T13:44:10Z"
    status: "True"
    type: PodReadyToStartContainers
  - lastProbeTime: null
    lastTransitionTime: "2025-08-29T13:43:59Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2025-08-29T13:44:10Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2025-08-29T13:44:10Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2025-08-29T13:43:59Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: containerd://2a182cf88454595004cefaf2ba18fb1bfc4a29b103dce6267862e1641eae0eb0
    image: docker.io/pjmartin/log-reader:1.10
    imageID: docker.io/pjmartin/log-reader@sha256:26b87b35c2aae1daad08c8fd129fed71a1b42359946db42393a24034b64868fd
    lastState: {}
    name: log-reader
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2025-08-29T13:44:04Z"
    volumeMounts:
    - mountPath: /app/logs
      name: log-output
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-slh7j
      readOnly: true
      recursiveReadOnly: Disabled
  - containerID: containerd://1a175dcfa23fb4a0f438be7e07416b53da16b25c7ab1d00db02f832eea959d93
    image: docker.io/pjmartin/log-writer:1.10
    imageID: docker.io/pjmartin/log-writer@sha256:da9bc4c3d7c0c124aef9ecd571b65b7adba2a26e8ee464dd2ba98311d459b32a
    lastState: {}
    name: log-writer
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2025-08-29T13:44:10Z"
    volumeMounts:
    - mountPath: /app/logs
      name: log-output
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-slh7j
      readOnly: true
      recursiveReadOnly: Disabled
  hostIP: 172.18.0.5
  hostIPs:
  - ip: 172.18.0.5
  phase: Running
  podIP: 10.42.1.7
  podIPs:
  - ip: 10.42.1.7
  qosClass: BestEffort
  startTime: "2025-08-29T13:43:59Z"
➜ k exec -ti log-output-deployment-7576d8764b-lmtds -c log-writer -- sh
# ls /app/logs
log_output.log
# cat /app/logs/log_output.log
2025-08-29 13:44:10,074 - INFO - Server started with hash Pec9Vx43E0
2025-08-29 13:44:10,074 - INFO - server id: Pec9Vx43E0 - hash: efasMzdKgS
2025-08-29 13:44:15,086 - INFO - server id: Pec9Vx43E0 - hash: QZwscwyFke
2025-08-29 13:44:20,093 - INFO - server id: Pec9Vx43E0 - hash: 8HJpmztjhI
2025-08-29 13:44:25,095 - INFO - server id: Pec9Vx43E0 - hash: 55ki9x23CB
2025-08-29 13:44:30,104 - INFO - server id: Pec9Vx43E0 - hash: ywQe8Gotej
2025-08-29 13:44:35,110 - INFO - server id: Pec9Vx43E0 - hash: tmjedC83RE
2025-08-29 13:44:40,119 - INFO - server id: Pec9Vx43E0 - hash: ImMwGLQPNl
2025-08-29 13:44:45,128 - INFO - server id: Pec9Vx43E0 - hash: Ib8rmi6TyS
2025-08-29 13:44:50,130 - INFO - server id: Pec9Vx43E0 - hash: BoLYwN0ske
2025-08-29 13:44:55,145 - INFO - server id: Pec9Vx43E0 - hash: SCY55eXvtZ
2025-08-29 13:45:00,152 - INFO - server id: Pec9Vx43E0 - hash: 08EYtkKYaw
2025-08-29 13:45:05,157 - INFO - server id: Pec9Vx43E0 - hash: Bnx1sZ1kby
2025-08-29 13:45:10,165 - INFO - server id: Pec9Vx43E0 - hash: V07KSPX3sm
2025-08-29 13:45:15,175 - INFO - server id: Pec9Vx43E0 - hash: xitwkSVw1H
2025-08-29 13:45:20,186 - INFO - server id: Pec9Vx43E0 - hash: CzNGQCBKxm
2025-08-29 13:45:25,194 - INFO - server id: Pec9Vx43E0 - hash: 8tEOuXNMYy
2025-08-29 13:45:30,202 - INFO - server id: Pec9Vx43E0 - hash: 5b4Q9pMPUL
2025-08-29 13:45:35,214 - INFO - server id: Pec9Vx43E0 - hash: WcxowT5r52
2025-08-29 13:45:40,216 - INFO - server id: Pec9Vx43E0 - hash: EBZ8mDTWwk
2025-08-29 13:45:45,225 - INFO - server id: Pec9Vx43E0 - hash: kNTtjTGHF2
2025-08-29 13:45:50,237 - INFO - server id: Pec9Vx43E0 - hash: 2ZsxFZK84P
2025-08-29 13:45:55,246 - INFO - server id: Pec9Vx43E0 - hash: 69SNF4036Q
2025-08-29 13:46:00,257 - INFO - server id: Pec9Vx43E0 - hash: qgMiIAlDsx
2025-08-29 13:46:05,259 - INFO - server id: Pec9Vx43E0 - hash: PrLuv6hGPr
2025-08-29 13:46:10,260 - INFO - server id: Pec9Vx43E0 - hash: cv1QjxVpB9
2025-08-29 13:46:15,269 - INFO - server id: Pec9Vx43E0 - hash: 2aT0PW6ueL
2025-08-29 13:46:20,274 - INFO - server id: Pec9Vx43E0 - hash: e8hQ7hwYsP
2025-08-29 13:46:25,284 - INFO - server id: Pec9Vx43E0 - hash: jxzAMZDbtY
2025-08-29 13:46:30,286 - INFO - server id: Pec9Vx43E0 - hash: 9YQGzXjHrM
2025-08-29 13:46:35,293 - INFO - server id: Pec9Vx43E0 - hash: 3YyPFqpi4V
2025-08-29 13:46:40,302 - INFO - server id: Pec9Vx43E0 - hash: WFwPRi5g2y
2025-08-29 13:46:45,310 - INFO - server id: Pec9Vx43E0 - hash: Bfo3fpocM7
2025-08-29 13:46:50,316 - INFO - server id: Pec9Vx43E0 - hash: NCP4kDs4Mu
2025-08-29 13:46:55,320 - INFO - server id: Pec9Vx43E0 - hash: X4D2P5fcZl
2025-08-29 13:47:00,329 - INFO - server id: Pec9Vx43E0 - hash: nC8B2Hhmdc
2025-08-29 13:47:05,336 - INFO - server id: Pec9Vx43E0 - hash: BZxUcYkr8i
2025-08-29 13:47:10,339 - INFO - server id: Pec9Vx43E0 - hash: OMniVeHSZa
2025-08-29 13:47:15,348 - INFO - server id: Pec9Vx43E0 - hash: ABs7MY2o6D
# ^C
#
command terminated with exit code 130
➜ curl localhost:8081/
<h1>HTTP Server ID: 4Q78EX6YIk</h1><br>2025-08-29 13:44:10,074 - INFO - Server started with hash Pec9Vx43E0
<br>2025-08-29 13:44:10,074 - INFO - server id: Pec9Vx43E0 - hash: efasMzdKgS
<br>2025-08-29 13:44:15,086 - INFO - server id: Pec9Vx43E0 - hash: QZwscwyFke
<br>2025-08-29 13:44:20,093 - INFO - server id: Pec9Vx43E0 - hash: 8HJpmztjhI
<br>2025-08-29 13:44:25,095 - INFO - server id: Pec9Vx43E0 - hash: 55ki9x23CB
<br>2025-08-29 13:44:30,104 - INFO - server id: Pec9Vx43E0 - hash: ywQe8Gotej
<br>2025-08-29 13:44:35,110 - INFO - server id: Pec9Vx43E0 - hash: tmjedC83RE
<br>2025-08-29 13:44:40,119 - INFO - server id: Pec9Vx43E0 - hash: ImMwGLQPNl
<br>2025-08-29 13:44:45,128 - INFO - server id: Pec9Vx43E0 - hash: Ib8rmi6TyS
<br>2025-08-29 13:44:50,130 - INFO - server id: Pec9Vx43E0 - hash: BoLYwN0ske
<br>2025-08-29 13:44:55,145 - INFO - server id: Pec9Vx43E0 - hash: SCY55eXvtZ
<br>2025-08-29 13:45:00,152 - INFO - server id: Pec9Vx43E0 - hash: 08EYtkKYaw
<br>2025-08-29 13:45:05,157 - INFO - server id: Pec9Vx43E0 - hash: Bnx1sZ1kby
<br>2025-08-29 13:45:10,165 - INFO - server id: Pec9Vx43E0 - hash: V07KSPX3sm
<br>2025-08-29 13:45:15,175 - INFO - server id: Pec9Vx43E0 - hash: xitwkSVw1H
<br>2025-08-29 13:45:20,186 - INFO - server id: Pec9Vx43E0 - hash: CzNGQCBKxm
<br>2025-08-29 13:45:25,194 - INFO - server id: Pec9Vx43E0 - hash: 8tEOuXNMYy
<br>2025-08-29 13:45:30,202 - INFO - server id: Pec9Vx43E0 - hash: 5b4Q9pMPUL
<br>2025-08-29 13:45:35,214 - INFO - server id: Pec9Vx43E0 - hash: WcxowT5r52
<br>2025-08-29 13:45:40,216 - INFO - server id: Pec9Vx43E0 - hash: EBZ8mDTWwk
<br>2025-08-29 13:45:45,225 - INFO - server id: Pec9Vx43E0 - hash: kNTtjTGHF2
<br>2025-08-29 13:45:50,237 - INFO - server id: Pec9Vx43E0 - hash: 2ZsxFZK84P
<br>2025-08-29 13:45:55,246 - INFO - server id: Pec9Vx43E0 - hash: 69SNF4036Q
<br>2025-08-29 13:46:00,257 - INFO - server id: Pec9Vx43E0 - hash: qgMiIAlDsx
<br>2025-08-29 13:46:05,259 - INFO - server id: Pec9Vx43E0 - hash: PrLuv6hGPr
<br>2025-08-29 13:46:10,260 - INFO - server id: Pec9Vx43E0 - hash: cv1QjxVpB9
<br>2025-08-29 13:46:15,269 - INFO - server id: Pec9Vx43E0 - hash: 2aT0PW6ueL
<br>2025-08-29 13:46:20,274 - INFO - server id: Pec9Vx43E0 - hash: e8hQ7hwYsP
<br>2025-08-29 13:46:25,284 - INFO - server id: Pec9Vx43E0 - hash: jxzAMZDbtY
<br>2025-08-29 13:46:30,286 - INFO - server id: Pec9Vx43E0 - hash: 9YQGzXjHrM
<br>2025-08-29 13:46:35,293 - INFO - server id: Pec9Vx43E0 - hash: 3YyPFqpi4V
<br>2025-08-29 13:46:40,302 - INFO - server id: Pec9Vx43E0 - hash: WFwPRi5g2y
<br>2025-08-29 13:46:45,310 - INFO - server id: Pec9Vx43E0 - hash: Bfo3fpocM7
<br>2025-08-29 13:46:50,316 - INFO - server id: Pec9Vx43E0 - hash: NCP4kDs4Mu
<br>2025-08-29 13:46:55,320 - INFO - server id: Pec9Vx43E0 - hash: X4D2P5fcZl
<br>2025-08-29 13:47:00,329 - INFO - server id: Pec9Vx43E0 - hash: nC8B2Hhmdc
<br>2025-08-29 13:47:05,336 - INFO - server id: Pec9Vx43E0 - hash: BZxUcYkr8i
<br>2025-08-29 13:47:10,339 - INFO - server id: Pec9Vx43E0 - hash: OMniVeHSZa
<br>2025-08-29 13:47:15,348 - INFO - server id: Pec9Vx43E0 - hash: ABs7MY2o6D
<br>2025-08-29 13:47:20,358 - INFO - server id: Pec9Vx43E0 - hash: C0JdIUk3Uv
<br>2025-08-29 13:47:25,366 - INFO - server id: Pec9Vx43E0 - hash: hB3FjhKEQS
<br>%
➜ log_output ⚡( 18-exercise-110-even-more-services)                                                         3.10.13 25 hours ago
▶
```