```bash
┌────────────────────────────────────────────┐
│          kubectl apply -f pod.yaml         │
└────────────────────────────────────────────┘
                 │
                 ▼
──────────────────────────────────────────────────────
             KUBE-APISERVER (control plane)
──────────────────────────────────────────────────────
  1. Authenticates the user (using kubeconfig)
  2. Validates and defaults the Pod object
  3. Runs admission controllers (mutating / validating)
  4. Persists the new Pod object in etcd (desired state)
  5. Responds to kubectl → "Pod created"
                 │
                 ▼
──────────────────────────────────────────────────────
                    ETCD (data store)
──────────────────────────────────────────────────────
  • Stores cluster state under `/registry/pods/default/my-busybox`
  • Source of truth for the desired & current state of the cluster
                 │
                 ▼
──────────────────────────────────────────────────────
                KUBE-SCHEDULER
──────────────────────────────────────────────────────
  • Watches API server for new Pods *without* `spec.nodeName`
  • Retrieves up-to-date node resource info from API server cache
  • Runs scheduling plugins (filtering, scoring, preemption)
  • Selects a node (e.g., `minikube`)
  • Writes binding back via API server → sets `spec.nodeName=minikube`
  • API server persists this change to etcd
                 │
                 ▼
──────────────────────────────────────────────────────
               KUBELET (on that node)
──────────────────────────────────────────────────────
  • Watches API server for Pods assigned to its node (`spec.nodeName`)
  • Detects “my-busybox → assigned to me”
  • Prepares Pod sandbox (namespaces, volumes, service account token)
  • Pulls image `busybox` (if not present)
  • Starts the container through CRI (containerd / Docker / CRI-O)
  • Reports Pod status (Pending → Running → etc.) to API server
                 │
                 ▼
──────────────────────────────────────────────────────
             API SERVER ←→ ETCD
──────────────────────────────────────────────────────
  • API server updates Pod `status` subresource
  • etcd stores the updated Pod object (now including `status.phase=Running`)
                 │
                 ▼
──────────────────────────────────────────────────────
           kubectl get pods → shows:
──────────────────────────────────────────────────────
  NAME         READY   STATUS    RESTARTS   AGE
  my-busybox   1/1     Running   0          30s
```

Each component is talking to the API server. Sends updates, watches for changes, etc.

```bash
           ┌────────────────────────────┐
           │  kube-apiserver + etcd     │
           └──────────▲──────▲──────────┘
                      │      │
     (watch unscheduled Pods)│
                      │      │(watch assigned Pods)
          ┌───────────┘      └─────────────┐
          │                                │
 ┌────────────────┐                ┌────────────────┐
 │ kube-scheduler │                │   kubelet(s)   │
 │  decides node  │                │ run containers │
 └────────────────┘                └────────────────┘
```
