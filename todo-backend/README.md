# Exercise: 2.9 The project, step 12

**Instead of creating a new python app for the cronjob i use the curl image to call the existing backend endpoint.**


Change namespace to "project" and deploy cronjob.

```bash
➜ kubens project
Context "k3d-k3s-default" modified.
Active namespace is "project".
➜ k apply -f todo-backend/manifests/cronjob.yaml
cronjob.batch/wiki-todo-cron created
```

Check cronjob

```bash
➜ k get pods
NAME                                       READY   STATUS    RESTARTS   AGE
todo-app-deployment-d45b78496-2qczh        1/1     Running   0          20h
todo-backend-deployment-84d6699855-8tlmg   1/1     Running   0          14h
➜ k get cronjobs.batch
NAME             SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
wiki-todo-cron   0 * * * *   <none>     False     0        <none>          30s
➜ k get jobs.batch
No resources found in project namespace.
```

Since cronjob is running every hour no events found for the job, patch it to run every minute and check jobs and events.

```bash
➜ k patch cronjob wiki-todo-cron -p '{"spec":{"schedule":"*/1 * * * *"}}'
cronjob.batch/wiki-todo-cron patched

➜ k get jobs
NAME                      STATUS     COMPLETIONS   DURATION   AGE
wiki-todo-cron-29284175   Complete   1/1           7s         23s
```

One job has run, check the todos page if there is a link to wikipedia.

```bash

➜ curl localhost:8081/

    <h1>The project App</h1>
    <img src="/image?ver=2025-09-04T14:49:40.575032+00:00" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>
      <li>⬜️ Read https://en.wikipedia.org/wiki/Pirahmetler,_Bolu</li><li>⬜️ Buy new cables to TS50x</li>
    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
    %
```

Forgot to patch cronjob to run every hour, lets see how many links there are.

```bash
➜ curl localhost:8081/

    <h1>The project App</h1>
    <img src="/image?ver=2025-09-05T05:35:30.979743+00:00" width="540" loading="lazy" alt="Random image" />
    <form method="POST" action="/" style="margin-top:12px">
      <input type="text" name="todo" required minlength="1" maxlength="140" size="40" />
      <button type="submit">Create todo</button>
    </form>
    <ul>
      <li>⬜️ Read https://en.wikipedia.org/wiki/List_of_fictional_Oxford_colleges</li><li>⬜️ Read https://en.wikipedia.org/wiki/Halima_Ali_Adan</li><li>⬜️ Read https://en.wikipedia.org/wiki/Pirahmetler,_Bolu</li><li>⬜️ Buy new cables to TS50x</li>
    </ul>
    <strong>DevOps with Kubernetes 2025</strong>
    %
```

**re-patch** cronjob to run every hour.

```bash
➜ k patch cronjob wiki-todo-cron -p '{"spec":{"schedule":"0 * * * *"}}'
cronjob.batch/wiki-todo-cron patched

➜ k get jobs.batch
NAME                      STATUS     COMPLETIONS   DURATION   AGE
wiki-todo-cron-29284176   Complete   1/1           3s         2m5s
wiki-todo-cron-29284177   Complete   1/1           4s         65s

➜ k get cronjobs.batch
NAME             SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
wiki-todo-cron   0 * * * *   <none>     False     0        115s            11m

➜ KubernetesSubmissions ⚡( 42-exercise-29-the-project-step-12)                                       3.10.13 15 hours ago
▶
```