# Chapter 2

# 1.1 Log output

```bash
➜ docker build -t pjmartin/log_output:1.1 . --push
[+] Building 4.0s (9/9) FINISHED                                                                                            docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                        0.0s
 => => transferring dockerfile: 113B                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/python:3.13-slim                                                                         0.5s
 => [internal] load .dockerignore                                                                                                           0.0s
 => => transferring context: 2B                                                                                                             0.0s
 => [1/3] FROM docker.io/library/python:3.13-slim@sha256:27f90d79cc85e9b7b2560063ef44fa0e9eaae7a7c3f5a9f74563065c5477cc24                   0.0s
 => => resolve docker.io/library/python:3.13-slim@sha256:27f90d79cc85e9b7b2560063ef44fa0e9eaae7a7c3f5a9f74563065c5477cc24                   0.0s
 => [internal] load build context                                                                                                           0.0s
 => => transferring context: 28B                                                                                                            0.0s
 => CACHED [2/3] WORKDIR /app                                                                                                               0.0s
 => CACHED [3/3] COPY app.py .                                                                                                              0.0s
 => exporting to image                                                                                                                      3.5s
 => => exporting layers                                                                                                                     0.0s
 => => exporting manifest sha256:7f73178cad8ab6cbc8d8efbc7041b3a2ca375eab14ae9384913c988f5c7173b6                                           0.0s
 => => exporting config sha256:2062bc8081590788db267c9c24e7d343834e66fcd2e2894645c388245b9632af                                             0.0s
 => => exporting attestation manifest sha256:3a0a4010547340c91f390aec13efff5f1686c5021fa577b01fef8bcd8041b001                               0.0s
 => => exporting manifest list sha256:9bd54eb6681b9a9b217164b17ccc8c2e87086485c81fa06935e6c9f979a81e6c                                      0.0s
 => => naming to docker.io/pjmartin/log_output:1.1                                                                                          0.0s
 => => unpacking to docker.io/pjmartin/log_output:1.1                                                                                       0.0s
 => => pushing layers                                                                                                                       2.0s
 => => pushing manifest for docker.io/pjmartin/log_output:1.1@sha256:9bd54eb6681b9a9b217164b17ccc8c2e87086485c81fa06935e6c9f979a81e6c       1.4s
 => [auth] pjmartin/log_output:pull,push token for registry-1.docker.io                                                                     0.0s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/7joxylrs80ovlv34c8zwhyznn
➜ log_output ⚡( new-root)                                                                                                    3.10.13 15:44:12
➜ alias k=kubectl
➜ k create deployment log-output --image=pjmartin/log_output:1.1
deployment.apps/log-output created
➜ k get pods
NAME                          READY   STATUS    RESTARTS   AGE
log-output-7d7695489f-jr77c   1/1     Running   0          13s
➜ k logs -f log-output-7d7695489f-jr77c
2025-08-27T13:47:36.661Z: - u1deSdDpgj
2025-08-27T13:47:41.664Z: - kQkp3TD2mj
2025-08-27T13:47:46.665Z: - 1oIlmmbWmK
2025-08-27T13:47:51.668Z: - wzC4HkhI7z
2025-08-27T13:47:56.668Z: - Fw1s953jkI
2025-08-27T13:48:01.672Z: - ZXtcW9OM6l
^C%
```