# ecs-adjust-taskcount
Given an ECS service/task, this lambda function will adjust the desired count of tasks based on the number of running ECS instances. 

cluster_size * desired_count = new_service_desired_count

Ex: 

cluster_size = 3 (3 ecs instances running)

desired_count = 1 

new_service_desired_count = 3 (1 * cluster_size)

If a scale up/down happen, lambda will increase/decrease of desired count of the service.


It might be useful when you don't have cloudwatch metrics to use as triggers to scale up/down your service or you just want to keep the number tasks(ex: tasks using HOST network) to the same number of running instances.

#### How to use
```
[1] Change values of variables on main.tf
[2] Export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
[3] Run terraform apply
```

#### How to test
```
[1] Scale up your ECS cluster
[2] Check if more tasks have been started
[3] Scale down your ECS cluster
[4] Check if tasks have been stopped
```
