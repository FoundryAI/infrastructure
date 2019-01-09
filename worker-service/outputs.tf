/**
 * Outputs.
 */

// The name of the api service
output "name" {
  value = "${var.name}"
}

// Full ARN of the repository
output "repository_arn" {
  value = "${var.ecr_arn}"
}

// The name of the repository
output "repository_name" {
  value = "${var.ecr_name}"
}

// The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)
output "repository_url" {
  value = "${var.ecr_repository_url}"
}

output "task_definition_arn" {
  value = "${aws_ecs_task_definition.worker.arn}"
}
