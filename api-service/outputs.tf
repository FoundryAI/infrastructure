/**
 * Outputs.
 */

// The name of the api service
output "name" {
  value = "${var.name}"
}

// The DNS name of the ALB
output "dns" {
  value = "${module.service.alb_dns_name}"
}

// The id of the ALB
output "alb" {
  value = "${module.service.alb}"
}

// The id of the ALB target group
output "alb_target_group" {
  value = "${module.service.alb_target_group}"
}

// The zone id of the ALB
output "zone_id" {
  value = "${module.service.zone_id}"
}

// The name of the repository
output "repository_name" {
  value = "${var.ecr_name}"
}
