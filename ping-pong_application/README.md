# Chapter 4

## Exercise: 3.4. Rewritten routing

Check the URL for the gateway.
```bash
➜ k get gateway -A
NAMESPACE   NAME         CLASS                ADDRESS                               PROGRAMMED   AGE
exercises   gateway-01   azure-alb-external   dmhcc6axe4cueece.fz43.alb.azure.com   True         29m
```

Access the ping-pong application through the gateway address.

```bash
➜ curl -i http://dmhcc6axe4cueece.fz43.alb.azure.com/pingpong
HTTP/1.1 200 OK
date: Tue, 04 Nov 2025 13:02:01 GMT
server: Microsoft-Azure-Application-LB/AGC
content-length: 51
content-type: application/json

{"message":"pong 1","counter":1,"storage":"memory"}%
```

Deploy new route with path rewrite so that the application is accessible at the root path `/`.

```bash
➜ k apply -f ping-pong_application/manifests/route.yaml
httproute.gateway.networking.k8s.io/my-route configured
```

Verify the pingpong is not avaialable at `/pingpong` anymore.

```bash
➜ curl -i http://dmhcc6axe4cueece.fz43.alb.azure.com/pingpong
HTTP/1.1 404 Not Found
date: Tue, 04 Nov 2025 13:02:35 GMT
server: Microsoft-Azure-Application-LB/AGC
content-length: 22
content-type: application/json

{"detail":"Not Found"}%
```

Verify the pingpong application is now available at the root path `/`.

```bash
➜ curl -i http://dmhcc6axe4cueece.fz43.alb.azure.com/
HTTP/1.1 200 OK
date: Tue, 04 Nov 2025 13:02:38 GMT
server: Microsoft-Azure-Application-LB/AGC
content-length: 51
content-type: application/json

{"message":"pong 2","counter":2,"storage":"memory"}%
```
