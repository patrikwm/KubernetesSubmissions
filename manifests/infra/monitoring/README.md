# Install Grafana and Prometheus using Helm


add helm repos and update

```bash
➜ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories
➜ helm repo add stable https://charts.helm.sh/stable
"stable" has been added to your repositories
➜ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "hashicorp" chart repository
...Successfully got an update from the "prometheus-community" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
```

create namespace

```bash
➜ k create namespace prometheus
namespace/prometheus created
➜ kubens prometheus
Context "k3d-k3s-default" modified.
Active namespace is "prometheus".
```

install prometheus and grafana

```bash
➜ helm install prometheus-community/kube-prometheus-stack --generate-name --namespace prometheus
NAME: kube-prometheus-stack-1757052367
LAST DEPLOYED: Fri Sep  5 08:06:08 2025
NAMESPACE: prometheus
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace prometheus get pods -l "release=kube-prometheus-stack-1757052367"

Get Grafana 'admin' user password by running:

  kubectl --namespace prometheus get secrets kube-prometheus-stack-1757052367-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

Access Grafana local instance:

  export POD_NAME=$(kubectl --namespace prometheus get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kube-prometheus-stack-1757052367" -oname)
  kubectl --namespace prometheus port-forward $POD_NAME 3000

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

Get prometheus and grafana info

```bash
➜ kubectl --namespace prometheus get pods -l "release=kube-prometheus-stack-1757052367"
Found existing alias for "kubectl". You should use: "k"
NAME                                                              READY   STATUS    RESTARTS   AGE
kube-prometheus-stack-1757-operator-d9cfb74b7-2ln75               1/1     Running   0          28m
kube-prometheus-stack-1757052367-kube-state-metrics-79df56pd5gl   1/1     Running   0          28m
kube-prometheus-stack-1757052367-prometheus-node-exporter-mzk6f   1/1     Running   0          28m
kube-prometheus-stack-1757052367-prometheus-node-exporter-rvqgt   1/1     Running   0          28m
kube-prometheus-stack-1757052367-prometheus-node-exporter-vqlg4   1/1     Running   0          28m
➜ kubectl --namespace prometheus get secrets kube-prometheus-stack-1757052367-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
Found existing alias for "kubectl". You should use: "k"
prom-operator
```

Install loki stack.

```bash
➜ helm upgrade --install loki --namespace=loki-stack grafana/loki-stack --set loki.image.tag=2.9.3
Release "loki" does not exist. Installing it now.
NAME: loki
LAST DEPLOYED: Fri Sep  5 08:38:53 2025
NAMESPACE: loki-stack
STATUS: deployed
REVISION: 1
NOTES:
The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana.

See http://docs.grafana.org/features/datasources/loki/ for more detail.
➜ kubectl get all -n loki-stack
Found existing alias for "kubectl". You should use: "k"
NAME                      READY   STATUS              RESTARTS   AGE
pod/loki-0                0/1     ContainerCreating   0          10s
pod/loki-promtail-r7b9d   0/1     ContainerCreating   0          10s
pod/loki-promtail-rc998   0/1     ContainerCreating   0          10s
pod/loki-promtail-xlz5h   0/1     ContainerCreating   0          10s

NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/loki              ClusterIP   10.43.47.150   <none>        3100/TCP   10s
service/loki-headless     ClusterIP   None           <none>        3100/TCP   10s
service/loki-memberlist   ClusterIP   None           <none>        7946/TCP   10s

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/loki-promtail   3         3         0       3            0           <none>          10s

NAME                    READY   AGE
statefulset.apps/loki   0/1     10s
➜ KubernetesSubmissions ⚡( main)                                                                            3.10.13 49 minutes ago
▶
```

Add loki port forwarding
```bash
 # kill leftover forwards (optional)
pkill -f "kubectl.*port-forward.*svc/loki.*3100" || true
kubectl -n loki-stack port-forward svc/loki 3100 >/dev/null 2>&1 &
sleep 1
```