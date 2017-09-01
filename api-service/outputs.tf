/**
 * Outputs.
 */

// The name of the api service
output "name" {
  value = "${var.name}"
}

// The DNS name of the ALB
output "dns" {
  value = "${module.api-alb.dns}"
}

// The id of the ALB
output "alb" {
  value = "${module.api-alb.alb}"
}

// The zone id of the ALB
output "zone_id" {
  value = "${module.api-alb.zone_id}"
}

// Full ARN of the repository
output "repository_arn" {
  value = "${module.api-alb.repository_arn}"
}

// The name of the repository
output "repository_name" {
  value = "${module.api-alb.repository_name}"
}

// The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)
output "repository_url" {
  value = "${module.api-alb.repository_url}"
}
