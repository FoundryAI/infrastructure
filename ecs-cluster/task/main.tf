/**
 * The task module creates an ECS task definition.
 *
 * Usage:
 *
 *     module "nginx" {
 *       source = "stack/task"
 *       name   = "nginx"
 *       image  = "nginx"
 *     }
 *
 */

/**
 * Required Variables.
 */


data "aws_caller_identity" "current" {}

/**
 * Resources.
 */

# The ECS task definition.

resource "null_resource" "repository" {
  triggers {
    url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  }
}

resource "aws_ecs_task_definition" "main" {
  family = "${var.name}"
  task_role_arn = "${var.role}"

  lifecycle {
    ignore_changes = [
      "image"]
    create_before_destroy = true
  }

  container_definitions = <<EOF
[
  {
    "cpu": ${var.cpu},
    "environment": ${var.env_vars},
    "essential": true,
    "command": ${var.command},
    "image": "${coalesce(var.image_repository_url, null_resource.repository.triggers.url)}/${var.image}:${var.image_version}",
    "memory": ${var.memory},
    "name": "${var.name}",
    "portMappings": ${var.ports},
    "entryPoint": ${var.entry_point},
    "mountPoints": [],
    "logConfiguration": {
      "logDriver": "${var.log_driver}",
      "options": {
        "awslogs-region": "${var.region}",
        "awslogs-group": "${coalesce(var.log_group, var.name)}",
        "awslogs-stream-prefix": "${var.log_prefix}"
      }
    }
  }
]
EOF
}

/**
 * Outputs.
 */

// The created task definition name
output "family" {
  value = "${aws_ecs_task_definition.main.family}"
}

// The created task definition ARN
output "arn" {
  value = "${aws_ecs_task_definition.main.arn}"
}

// The revision number of the task definition
output "revision" {
  value = "${aws_ecs_task_definition.main.revision}"
}