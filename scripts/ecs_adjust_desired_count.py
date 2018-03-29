import os
import sys

import boto3

def lambda_handler(event, context):
    ecs_cluster_name = os.environ.get("ECS_CLUSTER_NAME")
    ecs_service_name = os.environ.get("ECS_SERVICE_NAME")
    desired_count_max = int(os.environ.get("DESIRED_COUNT_MAX", 1))
    ecs_client = boto3.client('ecs')
    cluster_size = ecs_client.describe_clusters(clusters=[ecs_cluster_name])["clusters"][0]["registeredContainerInstancesCount"]
    service_size_running = ecs_client.describe_services(cluster=ecs_cluster_name, services=[ecs_service_name])["services"][0]["runningCount"]
    service_size_pending = ecs_client.describe_services(cluster=ecs_cluster_name, services=[ecs_service_name])["services"][0]["pendingCount"]
    desired_count = int(os.environ.get("DESIRED_COUNT")) * cluster_size
    if desired_count < desired_count_max:
        # no adjustments if pending tasks are found
        if service_size_pending == 0 and desired_count != service_size_running:
            print("Adjusting count from {} to {}".format(service_size_running, desired_count))
            ecs_client.update_service(cluster=ecs_cluster_name, service=ecs_service_name, desiredCount=desired_count)
        else:
            print("Nothing to adjust for now. desired_count={}, service_size_running={}, service_size_pending={}".format(desired_count, service_size_running, service_size_pending))
    else:
        print("DESIRED_COUNT_MAX reached! Exiting...")
