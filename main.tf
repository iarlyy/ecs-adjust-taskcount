# Variables
variable "region" {
  default = "us-west-1"
}

variable "name" {
  default = "A-NAME-HERE"
}

variable "ecs_cluster_name" {
  default = "ECS-CLUSTER-NAME"
}

variable "ecs_service_name" {
  default = "ECS-SERVICE-NAME"
}

variable "desired_count_per_instance" {
  default = "1" # x * number_of_ecs_instances
}

variable "desired_count_per_instance_max" {
  default = "10" # a stop number in case something is going wrong with the script
}

#aws
provider "aws" {
  region = "${var.region}"
}

data "archive_file" "ecs_adjust_desired_count_zip" {
  type        = "zip"
  source_dir  = "scripts/ecs_adjust_desired_count"
  output_path = "/tmp/ecs_adjust_desired_count.zip"
}

resource "aws_lambda_function" "ecs_adjust_desired_count" {
  filename         = "/tmp/ecs_adjust_desired_count.zip"
  source_code_hash = "${data.archive_file.ecs_adjust_desired_count_zip.output_base64sha256}"
  function_name    = "${var.name}"
  role             = "${data.terraform_remote_state.iam.lambda_default_role_arn}"
  handler          = "ecs_adjust_desired_count.lambda_handler"
  runtime          = "python3.6"

  environment {
    variables = {
      ECS_CLUSTER_NAME  = "${var.ecs_cluster_name}"
      ECS_SERVICE_NAME  = "${var.ecs_service_name}"
      DESIRED_COUNT     = "${var.desired_count_per_instance}"
      DESIRED_COUNT_MAX = "${var.desired_count_per_instance_max}"
    }
  }

  tags {
    Environment = "${var.environment}"
    Terraform   = true
  }
}

resource "aws_lambda_permission" "cloudwatch_perm_for_ecs_adjust_count" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ecs_adjust_desired_count.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ecs_adjust_desired_count.arn}"
}

resource "aws_cloudwatch_event_rule" "ecs_adjust_desired_count" {
  name                = "${var.name}"
  description         = "Managed by Terraform"
  schedule_expression = "cron(*/5 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "ecs_adjust_desired_count" {
  rule = "${aws_cloudwatch_event_rule.ecs_adjust_desired_count.name}"
  arn  = "${aws_lambda_function.ecs_adjust_desired_count.arn}"
}
