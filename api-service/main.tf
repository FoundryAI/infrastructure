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

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

module "api-alb" {
  source                             = "../api-alb"
  port                               = "${var.port}"
  name                               = "${var.name}"
  api_id                             = "${var.api_id}"
  api_root_id                        = "${var.api_root_id}"
  api_resource_name                  = "${var.api_resource_name}"
  api_endpoint                       = "${var.api_endpoint}"
  api_stage                          = "${var.api_stage}"
  environment                        = "${var.environment}"
  name                               = "${var.name}"
  subnet_ids                         = "${var.subnet_ids}"
  security_groups                    = "${var.security_groups}"
  port                               = "${var.port}"
  cluster                            = "${var.cluster}"
  log_bucket                         = "${var.log_bucket}"
  ssl_certificate_id                 = "${var.ssl_certificate_id}"
  iam_role                           = "${var.iam_role}"
  external_dns_name                  = "${var.external_dns_name}"
  internal_dns_name                  = "${var.internal_dns_name}"
  external_zone_id                   = "${var.external_zone_id}"
  internal_zone_id                   = "${var.internal_zone_id}"
  healthcheck                        = "${var.healthcheck}"
  container_port                     = "${var.container_port}"
  command                            = "${var.command}"
  desired_count                      = "${var.desired_count}"
  memory                             = "${var.memory}"
  cpu                                = "${var.cpu}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  codebuild_iam_role_arn             = "${var.codebuild_iam_role_arn}"
  codebuild_iam_role_role_id         = "${var.codebuild_iam_role_role_id}"
  codebuild_policy                   = "${var.codebuild_policy}"
  codepipeline_role_arn              = "${var.codepipeline_role_arn}"
  source_owner                       = "${var.source_owner}"
  source_repo                        = "${var.source_repo}"
  source_branch                      = "${var.source_branch}"
  oauth_token                        = "${var.oauth_token}"
  rds_db_name                        = "${var.rds_db_name}"
  rds_hostname                       = "${var.rds_hostname}"
  rds_username                       = "${var.rds_username}"
  rds_password                       = "${var.rds_password}"
  ecr_arn                            = "${var.ecr_arn}"
  ecr_name                           = "${var.ecr_name}"
  ecr_repository_url                 = "${var.ecr_repository_url}"
  aws_access_key                     = "${var.aws_access_key}"
  aws_secret_key                     = "${var.aws_secret_key}"
  vpc_id                             = "${var.vpc_id}"
  slack_webhook                      = "${var.slack_webhook}"
}

module "api_gateway" {
  source = "../api-gateway"
  environment = "${var.environment}"
  api_id = "${var.api_id}"
  api_root_id = "${var.api_root_id}"
  api_endpoint = "${var.api_endpoint}"
  api_stage = "${var.api_stage}"
  resource_name = "${var.api_resource_name}"
  elb_dns = "${module.api-alb.dns}"
}
