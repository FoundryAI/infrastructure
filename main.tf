/**
 * The stack module combines sub modules to create a complete
 * api with `vpc`, included ecs clusters & postgres databases
 * and a bastion node that enables you to access all instances.
 *
 * Usage:
 *
 *    module "api" {
 *      source      = "hud-ai-api-services"
 *      name        = "hud-ai-api"
 *      environment = "production"
 *    }
 *
 */

module "api" {
  source = "./rest-api"
  api_name = "${var.name}"
  environment = "${var.environment}"
  api_endpoint = "${var.api_endpoint}"
  ssl_certificate_id = "${var.ssl_certificate_id}"

}

module "bastion" {
  source = "./bastion"
  region = "${var.region}"
  instance_type = "${var.bastion_instance_type}"
  security_groups = "${module.security_groups.external_ssh},${module.security_groups.internal_ssh}"
  vpc_id = "${module.vpc.id}"
  subnet_id = "${element(module.vpc.external_subnets, 0)}"
  key_name = "${coalesce(var.key_name, var.environment)}"
  environment = "${var.environment}"
}

module "defaults" {
  source = "./defaults"
  region = "${var.region}"
  cidr = "${var.cidr}"
}

module "dhcp" {
  source = "./dhcp"
  name = "${module.dns.name}"
  vpc_id = "${module.vpc.id}"
  servers = "${coalesce(var.domain_name_servers, module.defaults.domain_name_servers)}"
}

module "dns" {
  source = "./dns"
  name = "${var.domain_name}"
  vpc_id = "${module.vpc.id}"
}

module "ecs_cluster" {
  source = "./ecs-cluster"
  name = "${coalesce(var.ecs_cluster_name, var.name)}"
  environment = "${var.environment}"
  vpc_id = "${module.vpc.id}"
  image_id = "${coalesce(var.ecs_ami, module.defaults.ecs_ami)}"
  subnet_ids = "${module.vpc.internal_subnets}"
  key_name = "${coalesce(var.key_name, var.environment)}"
  instance_type = "${var.ecs_instance_type}"
  instance_ebs_optimized = "${var.ecs_instance_ebs_optimized}"
  iam_instance_profile = "${module.iam_role.profile}"
  min_size = "${var.ecs_min_size}"
  max_size = "${var.ecs_max_size}"
  desired_capacity = "${var.ecs_desired_capacity}"
  region = "${var.region}"
  availability_zones = "${var.availability_zones}"
  root_volume_size = "${var.ecs_root_volume_size}"
  docker_volume_size = "${var.ecs_docker_volume_size}"
  docker_auth_type = "${var.ecs_docker_auth_type}"
  docker_auth_data = "${var.ecs_docker_auth_data}"
  security_groups = "${coalesce(var.ecs_security_groups, format("%s,%s,%s", module.security_groups.internal_ssh, module.security_groups.internal_elb, module.security_groups.external_elb))}"
  cloudwatch_prefix = "${var.environment}"
}

module "iam_role" {
  source = "./iam-role"
  name = "${var.name}"
  environment = "${var.environment}"
}

module "security_groups" {
  source = "./security-groups"
  name = "${var.name}"
  vpc_id = "${module.vpc.id}"
  environment = "${var.environment}"
  cidr = "${var.cidr}"
}

module "vpc" {
  source = "./vpc"
  name = "${var.name}"
  cidr = "${var.cidr}"
  internal_subnets = "${var.internal_subnets}"
  external_subnets = "${var.external_subnets}"
  availability_zones = "${var.availability_zones}"
  environment = "${var.environment}"
}