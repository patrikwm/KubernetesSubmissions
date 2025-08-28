# Networking in Kubernetes

## Diagram of NodePort Service

```bash
Your Laptop
+-----------------------------+
|                             |
|  curl http://localhost:8082 |
|  curl http://localhost:8081 |
+-----------------------------+
           |             |
           |             |
           v             v
   hostPort 8082   hostPort 8081
           |             |
           |             |
+----------+-------------+-------------------+
|         k3d containers (Docker)            |
|                                            |
|  [k3d-k3s-default-serverlb]  (loadbalancer)|
|     - 8081 -> 80 inside cluster            |
|                                            |
|  [k3d agent:0]                             |
|     - 8082 -> 30080 (NodePort)             |
+--------------------------------------------+
           |             |
           |             |
           v             v
   NodePort 30080    Cluster port 80
           |             |
           v             v
+--------------------------------------------+
|       Kubernetes Cluster Network            |
|                                            |
|  Service: todo-app-svc                     |
|    - type: NodePort                        |
|    - nodePort: 30080  <-- (external)       |
|    - port: 1234      <-- (cluster)         |
|    - targetPort:8081 <-- (Pod)             |
+--------------------------------------------+
                     |
                     v
               +-----------+
               |   Pod     |
               | todoapp   |
               | listens   |
               | on 8081   |
               +-----------+
```

## Diagram of Ingress

```bash
Your Laptop
+----------------------------------+
|                                  |
|  curl http://localhost:8081/     |  # host 8081 -> k3d L7 entry
+----------------------------------+
                 |
                 v
          hostPort 8081
                 |
+----------------+-----------------------------------+
|             k3d containers (Docker)                |
|                                                    |
|  [k3d-k3s-default-serverlb] (loadbalancer)         |
|      - forwards 8081 (host) -> 80 (cluster)        |
+----------------------------------------------------+
                 |
                 v
           Cluster port :80
                 |
+----------------------------------------------------+
|        Kubernetes Cluster Network                   |
|                                                     |
|  Ingress Controller (e.g., Traefik in k3s)          |
|    Ingress: log-output-ingress                      |
|      - rule: path "/"                               |
|      - backend: service log-output-svc:2345         |
|                (type: ClusterIP)                    |
|                    |                                |
|                    v                                |
|        Service: log-output-svc                      |
|          - port: 2345 (cluster-facing)              |
|          - targetPort: 3000 (Pod port)              |
+----------------------------------------------------+
                           |
                           v
                     +-----------------------+
                     | Pod from Deployment   |
                     |   name: log-output-…  |
                     |   app: logoutput      |
                     |   container: logoutput|
                     |   listens on :3000    |
                     +-----------------------+
```