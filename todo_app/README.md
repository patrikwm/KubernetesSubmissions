# Chapter 2

# 1.8. The project, step 5

```bash
➜ k apply -f manifests/deployment.yaml
deployment.apps/todo-app-deployment unchanged
➜ k apply -f manifests/service.yaml
service/todo-app-svc configured
➜ k get service
NAME           TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
kubernetes     ClusterIP   10.43.0.1     <none>        443/TCP    177m
todo-app-svc   ClusterIP   10.43.72.91   <none>        2345/TCP   52m
➜ k apply -f manifests/ingress.yaml
Error from server (BadRequest): error when creating "manifests/ingress.yaml": Ingress in version "v1" cannot be handled as a Ingress: json: cannot unmarshal string into Go struct field HTTPIngressRuleValue.spec.rules.http.paths of type []v1.HTTPIngressPath
➜ k apply -f manifests/ingress.yaml
Error from server (BadRequest): error when creating "manifests/ingress.yaml": Ingress in version "v1" cannot be handled as a Ingress: strict decoding error: unknown field "spec.rules[0].http.backend", unknown field "spec.rules[0].http.path", unknown field "spec.rules[0].http.type"
➜ k apply -f manifests/ingress.yaml
Error from server (BadRequest): error when creating "manifests/ingress.yaml": Ingress in version "v1" cannot be handled as a Ingress: strict decoding error: unknown field "spec.rules[0].http.backend", unknown field "spec.rules[0].http.path", unknown field "spec.rules[0].http.pathType"
➜ k apply -f manifests/ingress.yaml
ingress.networking.k8s.io/todo-app-ingress created

➜ date && curl localhost:8081 && k logs todo-app-deployment-bd879fdf5-ltjtw| tail -2
Thu Aug 28 14:10:16 CEST 2025
<strong>App instance hash:</strong> 1T2Rpy<br><strong>User request hash:</strong> 7vJ3nj
2025-08-28 12:09:26,872 - INFO - 10.42.3.3 - - [28/Aug/2025 12:09:26] "GET / HTTP/1.1" 200 -
2025-08-28 12:10:16,261 - INFO - 10.42.3.3 - - [28/Aug/2025 12:10:16] "GET / HTTP/1.1" 200 -
▶
```