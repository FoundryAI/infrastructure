/**
 * Outputs.
 */

// The name of the ELB
output "name" {
  value = "${module.elb.name}"
}

// The DNS name of the ELB
output "dns" {
  value = "${module.elb.dns}"
}

// The id of the ELB
output "elb" {
  value = "${module.elb.id}"
}

// The zone id of the ELB
output "zone_id" {
  value = "${module.elb.zone_id}"
}

// FQDN built using the zone domain and name (external)
output "external_fqdn" {
  value = "${module.elb.external_fqdn}"
}

// FQDN built using the zone domain and name (internal)
output "internal_fqdn" {
  value = "${module.elb.internal_fqdn}"
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
