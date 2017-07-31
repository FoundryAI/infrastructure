/**
 * The web-service is similar to the `service` module, but the
 * it provides a __public__ ELB instead.
 *
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "stack/api-service"
 *        name      = "auth-api-service"
 *        image     = "auth-api-service"
 *        cluster   = "default"
 *      }
 *
 */

/**
 * Resources.
 */

resource "aws_ecs_service" "main" {
  name = "${module.task.family}"
  cluster = "${var.cluster}"
  task_definition = "${module.task.arn}"
  desired_count = "${var.desired_count}"
  iam_role = "${var.iam_role}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent = "${var.deployment_maximum_percent}"

  load_balancer {
    elb_name = "${module.elb.id}"
    container_name = "${module.task.family}"
    container_port = "${var.container_port}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "api_gateway" {
  source = "../api-gateway"
  environment = "${var.environment}"
  api_id = "${var.api_id}"
  api_root_id = "${var.api_root_id}"
  api_endpoint = "${var.api_endpoint}"
  api_stage = "${var.api_stage}"
  resource_name = "${var.api_resource_name}"
  elb_dns = "${module.elb.dns}"
}

module "repository" {
  source = "../repository"
  image = "${var.image}"
}

module "task" {
  source = "../ecs-cluster/task"

  name = "${coalesce(var.name, replace(var.image, "/", "-"))}"
  image = "${var.image}"
  image_version = "${var.version}"
  command = "${var.command}"
  env_vars = "${var.env_vars}"
  memory = "${var.memory}"
  cpu = "${var.cpu}"
  log_group = "${var.name}"
  log_prefix = "${var.environment}"
//  role = "${var.iam_role}"

  ports = <<EOF
  [
    {
      "containerPort": ${var.container_port},
      "hostPort": ${var.port}
    }
  ]
EOF
}

module "elb" {
  source = "./elb"

  name = "${module.task.family}"
  port = "${var.port}"
  environment = "${var.environment}"
  subnet_ids = "${var.subnet_ids}"
  external_dns_name = "${coalesce(var.external_dns_name, var.name)}"
  internal_dns_name = "${coalesce(var.internal_dns_name, var.name)}"
  healthcheck = "${var.healthcheck}"
  external_zone_id = "${var.external_zone_id}"
  internal_zone_id = "${var.internal_zone_id}"
  security_groups = "${var.security_groups}"
  log_bucket = "${var.log_bucket}"
  ssl_certificate_id = "${var.ssl_certificate_id}"
}
