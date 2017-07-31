variable "name" {
  description = "The name of the application."
}

variable "environment" {}

variable "role_id" {
  description = "The iam role id"
}

resource "aws_codedeploy_app" "main" {
  name = "${var.name}"
}

resource "aws_codedeploy_deployment_config" "main" {
  deployment_config_name = "${var.name}-deployment-config"
  "minimum_healthy_hosts" {
    type = "HOST_COUNT"
    value = 2
  }
}

resource "aws_codedeploy_deployment_group" "main" {
  app_name = "${aws_codedeploy_app.main.name}"
  deployment_group_name = "${var.name}-deployment-group"
  service_role_arn = "${var.role_id}"
  deployment_config_name = "${aws_codedeploy_deployment_config.main.deployment_config_name}"

  ec2_tag_filter {
    key = "Environment"
    type = "KEY_AND_VALUE"
    value = "${var.environment}"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}