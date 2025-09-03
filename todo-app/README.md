# Chapter 3

## Exercise: 2.2. The project, step 8


### Clean up log_output

Remove log_output since i have set todo app and log output app to use same port / path.

```bash
k delete -f log_output/manifests -f ping-pong_application/manifests
deployment.apps "log-output-deployment" deleted
ingress.networking.k8s.io "log-output-ingress" deleted
service "log-output-svc" deleted
deployment.apps "ping-pong-deployment" deleted
ingress.networking.k8s.io "ping-pong-ingress" deleted
service "ping-pong-svc" deleted
```
