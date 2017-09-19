/**
 * Outputs.
 */

// The name of the api service
output "name" {
  value = "${var.name}"
}

// The DNS name of the ALB
output "dns" {
  value = "${module.alb.dns_name}"
}

// The id of the ALB
output "alb" {
  value = "${module.alb.arn}"
}

// The id of the ALB target group
output "alb_target_group" {
  value = "${module.alb.target_group_arn}"
}

// The zone id of the ALB
output "zone_id" {
  value = "${module.alb.zone_id}"
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
