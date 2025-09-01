# Chapter 2

# 1.13. The project, step 7


## Deploy new app.

```bash
➜ k apply -f todo_app/manifests
deployment.apps/todo-app-deployment configured
ingress.networking.k8s.io/todo-app-ingress unchanged
service/todo-app-svc unchanged
```

## Curl new todo app.

```bash
➜ curl localhost:8081/

    <h1>The project App</h1>
    <img src="data:image/jpeg;base64,<imageMD5-removed-by-pwm>" width="400"><br>
    <form method="POST" action="/">
        <input type="text" id="todo" name="todo" required minlength="4" maxlength="140" size="40" />
        <button type="submit">Create todo</button>
    </form>
        <ul>
        <li>Assemble carborator</li>
        <li>Learn Kubernetes</li>
        <li>Deploy AKS Cluster</li>
    </ul>
    <br>
    <strong>DevOps with Kubernetes 2025</strong>
    %
````
