output "api_id" {
  value = "${module.api.id}"
}

output "api_root_id" {
  value = "${module.api.root_id}"
}

output "api_stage" {
  value = "${module.api.stage}"
}

output "dns_zone_id" {
  value = "${module.dns.zone_id}"
}

output "ecs_cluster_name" {
  value = "${module.ecs_cluster.name}"
}

output "ecs_cluster_security_group_id" {
  value = "${module.ecs_cluster.security_group_id}"
}

output "cidr" {
  value = "${var.cidr}"
}

output "availability_zones" {
  value = "${module.vpc.availability_zones}"
}

output "internal_subnet_ids" {
  value = "${module.vpc.internal_subnets}"
}

output "external_subnet_ids" {
  value = "${module.vpc.external_subnets}"
}