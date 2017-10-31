/**
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "stack/api-service"
 *        name      = "auth-api-service"
 *        cluster   = "default"
 *      }
 *
 */

/**
 * Resources.
 */

module "service" {
  source = "./service"
  environment = "${var.environment}"
  name = "${var.name}"
  subnet_ids = "${var.subnet_ids}"
  security_groups = "${var.security_groups}"
  port = "${var.port}"
  cluster = "${var.cluster}"
  log_bucket = "${var.log_bucket}"
  ssl_certificate_id = "${var.ssl_certificate_id}"
  internal_dns_name = "${var.internal_dns_name}"
  internal_zone_id = "${var.internal_zone_id}"
  healthcheck = "${var.healthcheck}"
  container_port = "${var.container_port}"
  command = "${var.command}"
  desired_count = "${var.desired_count}"
  memory = "${var.memory}"
  cpu = "${var.cpu}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent = "${var.deployment_maximum_percent}"
  source_owner = "${var.source_owner}"
  source_repo = "${var.source_repo}"
  source_branch = "${var.source_branch}"
  oauth_token = "${var.oauth_token}"
  rds_db_name = "${var.rds_db_name}"
  rds_hostname = "${var.rds_hostname}"
  rds_username = "${var.rds_username}"
  rds_password = "${var.rds_password}"
  ecr_name = "${var.ecr_name}"
  aws_access_key = "${var.aws_access_key}"
  aws_secret_key = "${var.aws_secret_key}"
  vpc_id = "${var.vpc_id}"
  slack_webhook = "${var.slack_webhook}"
  internal_alb = "${var.internal_alb}"
  codebuild_image = "${var.codebuild_image}"
  codebuild_instance_type = "${var.codebuild_instance_type}"
}

module "api_gateway" {
  source = "../api-gateway"
  environment = "${var.environment}"
  api_id = "${var.api_id}"
  api_root_id = "${var.api_root_id}"
  api_endpoint = "${var.api_endpoint}"
  api_stage = "${var.api_stage}"
  resource_name = "${var.api_resource_name}"
  elb_dns = "${module.service.alb_dns_name}"
}
