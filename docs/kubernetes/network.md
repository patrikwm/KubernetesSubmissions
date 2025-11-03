# Kubernetes Networking

Each server in the network has its own IP address, and Kubernetes builds on this foundation to provide networking for Pods and Services.

Each host IP is provided via DHCP or static configuration. This is the same as the Node IP in Kubernetes.

In a Kubernetes cluster a CNI (Container Network Interface) plugin is used to provide networking for Pods. Popular CNI plugins include Calico, Flannel, Weave, and Cilium.

These plugins create a virtual network that allows Pods to communicate with each other across nodes. They are routed to eachother via routing tables set up on each node.


| CNI Plugin | Routing Method |
|------------|----------------|
| Calico     | BGP            |
| Flannel    | VXLAN          |
| Weave      | Weave Mesh     |
| Cilium     | eBPF           |

To check what CNI plugin is in use, you can inspect the network configuration on the nodes or check the installed DaemonSets in the kube-system namespace.
```bash
➜ kubectl get daemonsets -n kube-system
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-proxy   1         1         1       1            1           kubernetes.io/os=linux   20h
```

Since there is no daemonset for a CNI plugin in this example, we can check the CNI configuration files directly on the node. If you are using Minikube, you can access the Minikube VM and check the CNI configuration files located in `/etc/cni/net.d/`.

```bash
➜ docker ps -a
CONTAINER ID   IMAGE                                 COMMAND                  CREATED        STATUS        PORTS                                                                                                                                  NAMES
66db73c682ad   gcr.io/k8s-minikube/kicbase:v0.0.48   "/usr/local/bin/entr…"   20 hours ago   Up 20 hours   127.0.0.1:53955->22/tcp, 127.0.0.1:53957->2376/tcp, 127.0.0.1:53958->5000/tcp, 127.0.0.1:53959->8443/tcp, 127.0.0.1:53956->32443/tcp   minikube
➜ docker exec -ti minikube /bin/bash
root@minikube:/# cat /etc/cni/net.d/1-k8s.conflist

{
  "cniVersion": "0.4.0",
  "name": "bridge",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "bridge",
      "addIf": "true",
      "isDefaultGateway": true,
      "forceAddress": false,
      "ipMasq": true,
      "hairpinMode": true,
      "ipam": {
          "type": "host-local",
          "subnet": "10.244.0.0/16"
      }
    },
    {
      "type": "portmap",
      "capabilities": {
          "portMappings": true
      }
    },
    {
       "type": "firewall"
    }
  ]
}
```

Each node allocates Pod IPs locally, using a small file in `/var/lib/cni/networks/bridge/` to track assigned IPs.

```bash
root@minikube:/# ls -al /var/lib/cni/networks/bridge/
total 20
drwxr-xr-x 2 root root 4096 Oct 21 21:24 .
drwxr-xr-x 3 root root 4096 Oct 21 17:06 ..
-rw------- 1 root root   70 Oct 21 17:06 10.244.0.2
-rw------- 1 root root   70 Oct 21 21:24 10.244.0.6
-rw------- 1 root root   10 Oct 21 21:24 last_reserved_ip.0
-rwxr-x--- 1 root root    0 Oct 21 17:06 lock

root@minikube:/# cat /var/lib/cni/networks/bridge/10.244.0.6
aa190ebe8097d5e093644272dfaccc4a818f2249a022232780806a0e22222b0d

### Checking Pod IPs
➜ k get pods -A -o wide
NAMESPACE     NAME                               READY   STATUS    RESTARTS       AGE   IP             NODE       NOMINATED NODE   READINESS GATES
default       my-busybox                         1/1     Running   14 (57m ago)   16h   10.244.0.6     minikube   <none>           <none>
kube-system   coredns-66bc5c9577-s6gf2           1/1     Running   0              20h   10.244.0.2     minikube   <none>           <none>
kube-system   etcd-minikube                      1/1     Running   0              20h   192.168.49.2   minikube   <none>           <none>
kube-system   kube-apiserver-minikube            1/1     Running   0              20h   192.168.49.2   minikube   <none>           <none>
kube-system   kube-controller-manager-minikube   1/1     Running   0              20h   192.168.49.2   minikube   <none>           <none>
kube-system   kube-proxy-mbzxz                   1/1     Running   0              20h   192.168.49.2   minikube   <none>           <none>
kube-system   kube-scheduler-minikube            1/1     Running   0              20h   192.168.49.2   minikube   <none>           <none>
kube-system   storage-provisioner                1/1     Running   1 (20h ago)    20h   192.168.49.2   minikube   <none>           <none>
➜ docker inspect minikube |grep IPv4Address
                        "IPv4Address": "192.168.49.2"
```

So in this example, the CNI plugin is using a bridge network.
All kube-system pods are reachable on the minikube node IP.
While the pod `my-busybox` and coredns have their own Pod IPs.

To use calico in minikube, you can start minikube with the calico addon enabled:

```bash
minikube start --cni=calico --nodes=1
```

```bash
➜ k get pods -A -o wide
NAMESPACE     NAME                                       READY   STATUS    RESTARTS      AGE   IP              NODE       NOMINATED NODE   READINESS GATES
kube-system   calico-kube-controllers-59556d9b4c-rf57c   1/1     Running   1 (42s ago)   53s   10.244.120.65   minikube   <none>           <none>
kube-system   calico-node-gjplr                          1/1     Running   0             53s   192.168.49.2    minikube   <none>           <none>
kube-system   coredns-66bc5c9577-tbzdm                   1/1     Running   1 (39s ago)   53s   10.244.120.66   minikube   <none>           <none>
kube-system   etcd-minikube                              1/1     Running   0             59s   192.168.49.2    minikube   <none>           <none>
kube-system   kube-apiserver-minikube                    1/1     Running   0             59s   192.168.49.2    minikube   <none>           <none>
kube-system   kube-controller-manager-minikube           1/1     Running   0             59s   192.168.49.2    minikube   <none>           <none>
kube-system   kube-proxy-cpbwr                           1/1     Running   0             53s   192.168.49.2    minikube   <none>           <none>
kube-system   kube-scheduler-minikube                    1/1     Running   0             59s   192.168.49.2    minikube   <none>           <none>
kube-system   storage-provisioner                        1/1     Running   1 (22s ago)   57s   192.168.49.2    minikube   <none>           <none>
```

Now there is a calico-node pod running on the minikube node.

```bash
➜ docker exec -ti minikube /bin/bash
root@minikube:/# ls -al /etc/cni/net.d/
total 36
drwxr-xr-x 1 root root 4096 Oct 22 13:53 .
drwxr-xr-x 1 root root 4096 Sep  9 07:02 ..
-rw------- 1 root root  577 Oct 22 13:53 10-calico.conflist
-rw-r--r-- 1 root root  438 Jun 14  2023 100-crio-bridge.conf.mk_disabled
-rw-r--r-- 1 root root   78 Oct 22 13:53 200-loopback.conf
-rw-r--r-- 1 root root  639 Dec 26  2021 87-podman-bridge.conflist.mk_disabled
-rw------- 1 root root 2804 Oct 22 13:53 calico-kubeconfig
root@minikube:/# cat /etc/cni/net.d/10-calico.conflist
{
  "name": "k8s-pod-network",
  "cniVersion": "0.3.1",
  "plugins": [
    {
      "type": "calico",
      "log_level": "info",
      "log_file_path": "/var/log/calico/cni/cni.log",
      "datastore_type": "kubernetes",
      "nodename": "minikube",
      "mtu": 0,
      "ipam": { "type": "calico-ipam" },
      "policy": { "type": "k8s" },
      "kubernetes": { "kubeconfig": "/etc/cni/net.d/calico-kubeconfig" }},
    { "type": "portmap", "snat": true, "capabilities": {"portMappings": true} }
  ]
}
```

Calico runs in daemonset mode, so there is a calico-node pod on each node.

```bash
➜ k get daemonsets.apps -n kube-system
NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-node   1         1         1       1            1           kubernetes.io/os=linux   8m11s
kube-proxy    1         1         1       1            1           kubernetes.io/os=linux   8m13s
```

Calico-kube-controllers is running as a deployment. It makes sure that calico configuration matches the desired state in the cluster. (It watches the API server for changes.)


| Component | Responsibility |
|-----------|----------------|
| Kubelet | Detects new Pod → asks CRI to start it |
| CRI (containerd/Docker) | Calls CNI plugin to configure networking |
| CNI (Calico plugin) | Allocates IP, connects Pod, configures network namespace |
| Calico Node DaemonSet | Programs routes, enforces policies, handles BGP/VXLAN |
| Kubelet → API Server | Reports Pod’s IP and status |
| Other Nodes’ Calico | Learn via BGP/VXLAN where the new Pod lives |
