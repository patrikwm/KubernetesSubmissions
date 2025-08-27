# Chapter 2

# 1.2 Todo app

```bash
➜ docker build . --tag pjmartin/todo_app:1.2 --push
[+] Building 8.2s (12/12) FINISHED                                                                                                     docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                   0.0s
 => => transferring dockerfile: 215B                                                                                                   0.0s
 => [internal] load metadata for docker.io/library/python:3.10.13-slim                                                                 1.1s
 => [auth] library/python:pull token for registry-1.docker.io                                                                          0.0s
 => [internal] load .dockerignore                                                                                                      0.0s
 => => transferring context: 2B                                                                                                        0.0s
 => [1/5] FROM docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922           0.0s
 => => resolve docker.io/library/python:3.10.13-slim@sha256:1326d0fd281d283b077fd249e618339a44c9ca5aae6e05cb4f069a087e827922           0.0s
 => [internal] load build context                                                                                                      0.3s
 => => transferring context: 22.53MB                                                                                                   0.3s
 => CACHED [2/5] WORKDIR /app                                                                                                          0.0s
 => CACHED [3/5] COPY requirements.txt requirements.txt                                                                                0.0s
 => CACHED [4/5] RUN pip install -r requirements.txt                                                                                   0.0s
 => [5/5] COPY . .                                                                                                                     0.2s
 => exporting to image                                                                                                                 6.5s
 => => exporting layers                                                                                                                0.6s
 => => exporting manifest sha256:f30d50cf65a4fb60af54c4334ff0c5ab7fd7755a297c7d7917486476900758ad                                      0.0s
 => => exporting config sha256:2a0679ab70c322b47b59d0221e548996b1ab6b759da432cf14b7df42b9295b04                                        0.0s
 => => exporting attestation manifest sha256:8bb4735a360c28477f3291d6f9d790a53c6a2023841a5930b9c9fddae2c822fa                          0.0s
 => => exporting manifest list sha256:ca184378819c73e1c4d3e97549bcd297a8b6e8006f123ba7d91f71b3f5f31052                                 0.0s
 => => naming to docker.io/pjmartin/todo_app:1.2                                                                                       0.0s
 => => unpacking to docker.io/pjmartin/todo_app:1.2                                                                                    0.2s
 => => pushing layers                                                                                                                  2.7s
 => => pushing manifest for docker.io/pjmartin/todo_app:1.2@sha256:ca184378819c73e1c4d3e97549bcd297a8b6e8006f123ba7d91f71b3f5f31052    2.9s
 => [auth] pjmartin/todo_app:pull,push token for registry-1.docker.io                                                                  0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/x8zkagm0epbjns9mdy52ltahh
➜ docker run --rm -e PORT=8081 -p 8080:8081 pjmartin/todo_app:1.2
 * Serving Flask app 'app'
 * Debug mode: off
2025-08-27 14:06:51,439 - INFO - Server started in port 8081
2025-08-27 14:06:51,441 - INFO - WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI
server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:8081
 * Running on http://172.17.0.2:8081
2025-08-27 14:06:51,441 - INFO - Press CTRL+C to quit
^C%
➜ kubectl create deployment todo-app --image pjmartin/todo_app:1.2
deployment.apps/todo-app created
➜ kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
log-output-7d7695489f-jr77c   1/1     Running   0          19m
todo-app-85546b7976-7gzn9     1/1     Running   0          16s
➜ todo_app ⚡( main)                                                                                                  3.10.13 7 minutes ago

➜ kubectl logs -f todo-app-85546b7976-7gzn9
2025-08-27 14:07:07,221 - INFO - Server started in port 8080
 * Serving Flask app 'app'
 * Debug mode: off
2025-08-27 14:07:07,222 - INFO - WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:8080
 * Running on http://10.42.2.21:8080
2025-08-27 14:07:07,222 - INFO - Press CTRL+C to quit
```