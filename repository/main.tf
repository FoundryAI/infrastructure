/**
 * The task module creates an ECS repository.
 *
 * Usage:
 *
 *     module "api-repository" {
 *       source = "stack/repository"
 *       image  = "api"
 *     }
 *
 */

/**
 * Required Variables.
 */

variable "image" {
  description = "Name of the repository"
}

resource "aws_ecr_repository" "main" {
  name = "${var.image}"
}

// Full ARN of the repository
output "arn" {
  value = "${aws_ecr_repository.main.arn}"
}

// The name of the repository
output "name" {
  value = "${aws_ecr_repository.main.name}"
}

// The registry ID where the repository was created
output "registry_id" {
  value = "${aws_ecr_repository.main.registry_id}"
}

// The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)
output "repository_url" {
  value = "${aws_ecr_repository.main.repository_url}"
}