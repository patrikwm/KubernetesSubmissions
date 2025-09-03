
# Chapter 3

## 2.5. Documentation and ConfigMaps

Check ConfigMap content.

```bash
➜ cat log_output/manifests/configmap.yaml
───────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
       │ File: log_output/manifests/configmap.yaml
───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1   │ apiVersion: v1
   2   │ kind: ConfigMap
   3   │ metadata:
   4   │   name: log-output-config
   5   │ data:
   6   │   information.txt: |
   7   │     Hello from information.txt!
   8   │   MESSAGE: "Hello Message variable!"
───────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

Apply manifests

```bash
➜ k apply -f log_output/manifests
configmap/log-output-config created
deployment.apps/log-output-deployment created
ingress.networking.k8s.io/log-output-ingress created
service/log-output-svc created
```

Verify Output is from ConfigMap

```bash
➜ curl localhost:8081/logs
HTTP Server ID: dbd069f7-92ba-49c7-82b9-ae0c2e621538
<br>file content: Hello from information.txt!

<br>env variable: Hello Message variable!
<br>Ping / Pongs: 2
</br></br>2025-09-03 14:37:36,817 - INFO - server id: dJ8nCAQKpw - hash: TKC4mYLhQY
<br>2025-09-03 14:37:41,819 - INFO - server id: dJ8nCAQKpw - hash: 9ZdJKySro7
<br>2025-09-03 14:37:46,821 - INFO - server id: dJ8nCAQKpw - hash: wXz39tm6ud
<br>2025-09-03 14:37:51,823 - INFO - server id: dJ8nCAQKpw - hash: vuKhrVbx6w
<br>2025-09-03 14:37:56,829 - INFO - server id: dJ8nCAQKpw - hash: p8weUznpfU
<br>2025-09-03 14:38:01,834 - INFO - server id: dJ8nCAQKpw - hash: wlvkHqliL5
<br>2025-09-03 14:38:06,835 - INFO - server id: dJ8nCAQKpw - hash: nQirIAna2L
<br>2025-09-03 14:38:40,243 - INFO - Server started with hash B4qToFKsc2
<br>2025-09-03 14:38:40,243 - INFO - server id: B4qToFKsc2 - hash: ifsXH9h6w4
<br>2025-09-03 14:38:45,246 - INFO - server id: B4qToFKsc2 - hash: 86knWDQo3p
<br>%
```

Update ConfigMap file content. (Variable changes require redeploy of pod so its not changed on the fly.)

```bash
➜ cat log_output/manifests/configmap.yaml
───────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
       │ File: log_output/manifests/configmap.yaml
───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1   │ apiVersion: v1
   2   │ kind: ConfigMap
   3   │ metadata:
   4   │   name: log-output-config
   5   │ data:
   6   │   information.txt: |
   7   │     NEW MESSAGE IN FILE!
   8   │   MESSAGE: "Hello Message variable!"
───────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
```


Apply updated config map

```bash
➜ k apply -f log_output/manifests
configmap/log-output-config configured
deployment.apps/log-output-deployment unchanged
ingress.networking.k8s.io/log-output-ingress unchanged
service/log-output-svc unchanged
```

Verify file is read on each request

```bash

➜ curl localhost:8081/logs
HTTP Server ID: dbd069f7-92ba-49c7-82b9-ae0c2e621538
<br>file content: NEW MESSAGE IN FILE!

<br>env variable: Hello Message variable!
<br>Ping / Pongs: 2
</br></br>2025-09-03 14:39:15,269 - INFO - server id: B4qToFKsc2 - hash: 39W2MVPGpg
<br>2025-09-03 14:39:20,277 - INFO - server id: B4qToFKsc2 - hash: h93ITed4QN
<br>2025-09-03 14:39:25,284 - INFO - server id: B4qToFKsc2 - hash: 6BFD2JrON0
<br>2025-09-03 14:39:30,288 - INFO - server id: B4qToFKsc2 - hash: xkU7oC445n
<br>2025-09-03 14:39:35,289 - INFO - server id: B4qToFKsc2 - hash: Z0N3fRAX0t
<br>2025-09-03 14:39:40,291 - INFO - server id: B4qToFKsc2 - hash: UUnE0ZDSQ9
<br>2025-09-03 14:39:45,294 - INFO - server id: B4qToFKsc2 - hash: W9T4MAs3Zn
<br>2025-09-03 14:39:50,299 - INFO - server id: B4qToFKsc2 - hash: 21ZD0rYao7
<br>2025-09-03 14:39:55,308 - INFO - server id: B4qToFKsc2 - hash: Vscac29vrT
<br>2025-09-03 14:40:00,312 - INFO - server id: B4qToFKsc2 - hash: uATb5lMd8Z
<br>%
➜ KubernetesSubmissions ⚡( 34-exercise-25-documentation-and-configmaps)                                                       3.10.13 3 hours ago
▶
```