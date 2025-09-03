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
- [2.1.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.1/log_output/)
- [2.2.](https://github.com/patrikwm/KubernetesSubmissions/tree/2.2/todo-app/)



## Notes


### log_output

endpoint: `/`

Outputs a random string with a timestamp every 5 seconds to stdout and to a log file.

### ping-pong_application

endpoint: `/pingpong`

A ping-pong application with one endpoint. Saves output to LOG_FILE environment variable or to ping-pong.log by default.


### todo_app

endpoint: `/`

Todo application with one endpoint. Outputs an app instance hash and a user request hash. Uses DATA_DIR environment variable or ../image-downloader/.data by default to store data.