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