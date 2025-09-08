# KubernetesSubmissions

## Exercises

### Chapter 2

- [1.1.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.1/log_output/)
- [1.2.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.2/todo_app/)
- [1.3.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.3/log_output/)
- [1.4.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.4/todo_app/)
- [1.5.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.5/todo_app/)
- [1.6.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.6/todo_app/)
- [1.7.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.7/log_output/)
- [1.8.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.8/todo_app/)
- [1.9.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.9/ping-pong_application/)
- [1.10.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.10/log_output/)
- [1.11.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.11/log_output/)
- [1.12.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.12/todo_app/)
- [1.13.](https://github.com/patrikwm/KubernetesSubmissions/tree/1.13/todo_app/)

### Chapter 3

- [2.1.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.1/log_output/)
- [2.2.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.2/todo-app/)
- [2.3.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.3/log_output/)
- [2.4.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.4/todo-app/)
- [2.5.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.5/log_output/)
- [2.6.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.6/todo-app/)
- [2.7.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.7/postgres/)
- [2.8.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.8/todo-backend/)
- [2.9.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.9/todo-backend/)
- [2.10.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.10/todo-app/)

### Chapter 4

- [AKS cluster setup](https://github.com/patrikwm/KubernetesSubmissions/tree/3.0/aks-cluster/)
- [3.1.](https://github.com/patrikwm/KubernetesSubmissions/tree/3.1/ping-pong_application/)


## Scripts

- Setup AKS Cluster: `./script/setup-aks-cluster.sh`
- Delete AKS Cluster: `./script/delete-aks-cluster.sh`
- Update deployments: `./script/update-deployments.sh <deployment-name> <image-version>`
- Deploy Postgres: `./script/deploy-postgres.sh`


## Notes


### log_output

endpoint: `/logs`

Outputs a random string with a timestamp every 5 seconds to stdout and to a log file.

### ping-pong_application

endpoint: `/pingpong`

A ping-pong application with one endpoint. Saves output to LOG_FILE environment variable or to ping-pong.log by default.


### todo_app

endpoint: `/`

Todo application with one endpoint. Outputs an app instance hash and a user request hash. Uses DATA_DIR environment variable or ../image-downloader/.data by default to store data.