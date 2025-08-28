# Chapter 2

# 1.5 The project, step 3

*new docker image built and pushed with version 1.5*

```bash
➜ cat manifests/deployment.yaml|grep -A 3 "env:"
          env:
            - name: PORT
              value: "8081"

➜ k apply -f manifests/deployment.yaml
deployment.apps/todo-app-deployment created

➜ k port-forward todo-app-deployment-7968d8bccc-vxl8h 8080:8081
Forwarding from 127.0.0.1:8080 -> 8081
Forwarding from [::1]:8080 -> 8081
Handling connection for 8080

➜ curl http://localhost:8080
<strong>App instance hash:</strong> d54Nfh<br><strong>User request hash:</strong> vqTvIQ
➜ curl http://localhost:8080
<strong>App instance hash:</strong> d54Nfh<br><strong>User request hash:</strong> tRNMrx
```