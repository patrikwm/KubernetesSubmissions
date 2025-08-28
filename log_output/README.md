# Chapter 2

# 1.7. External access with Ingress

```bash
➜ k apply -f manifests/deployment.yaml
deployment.apps/log-output-deployment created

➜ k apply -f manifests/service.yaml
service/log-output-svc created

➜ k apply -f manifests/ingress.yaml
ingress.networking.k8s.io/log-output-ingress created

➜ k logs log-output-deployment-86f659b74c-28c7x && curl localhost:8081
2025-08-28T11:38:21.708Z: - COL9hh5BSl
2025-08-28 11:38:21,708 - INFO - Server started in port 3000
2025-08-28 11:38:21,708 - INFO - Initial random string: zNHRGksan7
 * Serving Flask app 'app'
 * Debug mode: off
2025-08-28 11:38:21,710 - INFO - WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:3000
 * Running on http://10.42.3.5:3000
2025-08-28 11:38:21,710 - INFO - Press CTRL+C to quit
2025-08-28T11:38:26.715Z: - gn1rCZg6lw
2025-08-28T11:38:31.719Z: - n1TNNLTWNm
2025-08-28T11:38:36.725Z: - V7lQIW58H5
2025-08-28T11:38:41.733Z: - s25bDZN7WR
2025-08-28 11:38:41,955 - INFO - 10.42.3.3 - - [28/Aug/2025 11:38:41] "GET / HTTP/1.1" 200 -
2025-08-28 11:38:42,001 - INFO - 10.42.3.3 - - [28/Aug/2025 11:38:42] "GET /favicon.ico HTTP/1.1" 404 -
2025-08-28T11:38:46.738Z: - 9MMsIUq8lC
2025-08-28T11:38:51.744Z: - VGmn88Caxn
2025-08-28T11:38:56.750Z: - BmLJY27pHb
2025-08-28T11:39:01.751Z: - SVqsH3KFjJ
2025-08-28 11:39:05,621 - INFO - 10.42.3.3 - - [28/Aug/2025 11:39:05] "GET / HTTP/1.1" 200 -
2025-08-28T11:39:06.758Z: - 61rp0vNRyK
2025-08-28T11:39:11.765Z: - WngH9SkytM
2025-08-28T11:39:16.766Z: - XLI7nd5oSx
2025-08-28T11:39:21.776Z: - Y2qON8SVIp
2025-08-28T11:39:26.778Z: - KHw8Vd5Izq
2025-08-28T11:39:31.784Z: - O5FulVDjbk
2025-08-28T11:39:36.790Z: - mbUOCiJZLN
2025-08-28T11:39:41.796Z: - aocMRD5Aiw
2025-08-28T11:39:46.803Z: - EMga8qGn7Q
2025-08-28T11:39:51.809Z: - 6XGOEbKvea
2025-08-28T11:39:56.819Z: - cXvW49saGY
{"random_string":"cXvW49saGY","timestamp":"2025-08-28T11:39:56.819Z"}

```