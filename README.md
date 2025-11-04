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
- [3.2.](https://github.com/patrikwm/KubernetesSubmissions/tree/3.2/ping-pong_application/)
- [3.3.](https://github.com/patrikwm/KubernetesSubmissions/tree/3.3/ping-pong_application/)
- [3.4.](https://github.com/patrikwm/KubernetesSubmissions/tree/3.4/ping-pong_application/)


## Scripts

Scripts are organized by purpose under the [`scripts/`](scripts/) directory.

### Infrastructure Scripts

Located in [`scripts/infrastructure/`](scripts/infrastructure/):

- [`config.sh`](scripts/infrastructure/config.sh) — Shared configuration for all infrastructure scripts.
- [`00-0-check-network-config.sh`](scripts/infrastructure/00-0-check-network-config.sh) — Validate network configuration and CIDR ranges.
- [`00-1-create-network.sh`](scripts/infrastructure/00-1-create-network.sh) — Create VNet and subnets for AKS.
- [`00-2-create-cluster.sh`](scripts/infrastructure/00-2-create-cluster.sh) — Create the AKS cluster.
- [`01-1-enable-ingress.sh`](scripts/infrastructure/01-1-enable-ingress.sh) — Enable NGINX ingress controller.
- [`02-1-enable-alb.sh`](scripts/infrastructure/02-1-enable-alb.sh) — Enable Application Gateway for Containers (ALB).
- [`02-2-create-alb.sh`](scripts/infrastructure/02-2-create-alb.sh) — Configure ALB subnet permissions.
- [`03-1-create-namespaces.sh`](scripts/infrastructure/03-1-create-namespaces.sh) — Create Kubernetes namespaces.
- [`verify-alb-setup.sh`](scripts/infrastructure/verify-alb-setup.sh) — Verify ALB installation and configuration.
- [`cleanup.sh`](scripts/infrastructure/cleanup.sh) — Delete the cluster and all resources.

### Application Deployment Scripts

Located in [`scripts/apps/`](scripts/apps/):

- [`deploy-postgres.sh`](scripts/apps/deploy-postgres.sh) — Deploy PostgreSQL StatefulSet.
- [`deploy-ping-pong.sh`](scripts/apps/deploy-ping-pong.sh) — Deploy the ping-pong application.
- [`deploy-log-output.sh`](scripts/apps/deploy-log-output.sh) — Deploy the log output application.
- [`deploy-todo-app.sh`](scripts/apps/deploy-todo-app.sh) — Deploy the todo frontend.
- [`deploy-todo-backend.sh`](scripts/apps/deploy-todo-backend.sh) — Deploy the todo backend with CronJob.

### Development Scripts

Located in [`scripts/dev/`](scripts/dev/):

- [`setup-venv.sh`](scripts/dev/setup-venv.sh) — Create and configure Python virtual environment for testing.
- [`run-tests.sh`](scripts/dev/run-tests.sh) — Run automated tests for deployed applications.
- [`port-forward.sh`](scripts/dev/port-forward.sh) — Forward Kubernetes services to localhost for local development.

### Quick Reference

See [`scripts/QUICKREF.md`](scripts/QUICKREF.md) for a condensed command reference.

For detailed usage instructions, see [`scripts/README.md`](scripts/README.md).


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


### Export sops key

```bash
export SOPS_AGE_KEY_FILE=$(pwd)/key.txt
```
