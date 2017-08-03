/**
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "stack/api-service"
 *        name      = "auth-api-service"
 *        image     = "auth-api-service"
 *        cluster   = "default"
 *      }
 *
 */

/**
 * Resources.
 */

data "aws_region" "current" {
  current = true
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.name}-deployments"
  acl = "private"

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_cloudformation_stack" "main" {
  name = "${var.name}-${var.environment}"
  template_body = "${file("${path.module}/templates/deployment-pipeline.yaml")}"

  parameters {
    GitHubRepo = "${var.source_repo}"
    GitHubBranch = "${var.source_branch}"
    GitHubToken = "${var.oauth_token}"
    GitHubUser = "${var.source_owner}"
    LoadBalancerName = "${module.elb.name}"
    Cluster = "${var.cluster}"
    TemplateBucket = "${aws_s3_bucket.main.bucket}"
    Name = "${var.name}-${var.environment}"
    ContainerName = "${var.name}-${var.environment}"
    ContainerPort = "${var.container_port}"
    Port = "${var.port}"
    DesiredCount = "${var.desired_count}"
    LoadBalancerName = "${module.elb.id}"
    RDS_DB_NAME = "${var.rds_db_name}"
    RDS_HOSTNAME = "${var.rds_hostname}"
    RDS_USERNAME = "${var.rds_username}"
    RDS_PASSWORD = "${var.rds_password}"
    AwslogsGroup = "${var.environment}"
    AwslogsRegion = "${data.aws_region.current.name}"
    AwslogsStreamPrefix = "${var.name}"
  }
}

//resource "aws_ecs_service" "main" {
//  name = "${module.task.family}"
//  cluster = "${var.cluster}"
//  task_definition = "${module.task.arn}"
//  desired_count = "${var.desired_count}"
//  iam_role = "${var.iam_role}"
//  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
//  deployment_maximum_percent = "${var.deployment_maximum_percent}"
//
//  load_balancer {
//    elb_name = "${module.elb.id}"
//    container_name = "${module.task.family}"
//    container_port = "${var.container_port}"
//  }
//
//  lifecycle {
//    create_before_destroy = true
//  }
//}

module "api_gateway" {
  source = "../api-gateway"
  environment = "${var.environment}"
  api_id = "${var.api_id}"
  api_root_id = "${var.api_root_id}"
  api_endpoint = "${var.api_endpoint}"
  api_stage = "${var.api_stage}"
  resource_name = "${var.api_resource_name}"
  elb_dns = "${module.elb.dns}"
}

//module "codebuild" {
//  source = "./codebuild"
//  iam_role_id = "${var.codebuild_iam_role_role_id}"
//  name = "${coalesce(var.name, replace(var.image, "/", "-"))}"
//  environment = "${var.environment}"
//  image = "${var.image}"
//  repo_url = "${var.source_repo}"
//  github_oauth_token = "${var.oauth_token}"
//  policy_arn = "${var.codebuild_policy}"
//  rds_db_name = "${var.rds_db_name}"
//  rds_hostname = "${var.rds_hostname}"
//  rds_password = "${var.rds_password}"
//  rds_username = "${var.rds_username}"
//}
//
//module "codepipeline" {
//  source = "./codepipeline"
//  name = "${coalesce(var.name, replace(var.image, "/", "-"))}"
//  environment = "${var.environment}"
//  image_version = "${var.version}"
//  memory = "${var.memory}"
//  cpu = "${var.cpu}"
//  ecs_container_env_vars = "${var.env_vars}"
//  elb_id = "${module.elb.id}"
//  cluster = "${var.cluster}"
//  role_arn = "${var.codepipeline_role_arn}"
//  ecs_iam_role = "${var.iam_role}"
//  port = "${var.port}"
//  container_port = "${var.container_port}"
//  codebuild_project_name = "${module.codebuild.name}"
//  codebuild_migration_project_name = "${module.codebuild.migration_name}"
//  source_owner = "${var.source_owner}"
//  source_repo = "${var.source_repo}"
//  source_branch = "${var.source_branch}"
//  repository_url = "${module.repository.repository_url}"
//  oauth_token = "${var.oauth_token}"
//  codebuild_iam_role_role_id = "${var.codebuild_iam_role_role_id}"
//}

//module "repository" {
//  source = "../repository"
//  image = "${var.image}"
//}

//module "task" {
//  source = "../ecs-cluster/task"
//
//  name = "${coalesce(var.name, replace(var.image, "/", "-"))}"
//  image = "${var.image}"
//  image_version = "${var.version}"
//  command = "${var.command}"
//  env_vars = "${var.env_vars}"
//  memory = "${var.memory}"
//  cpu = "${var.cpu}"
//  log_group = "${var.name}"
//  log_prefix = "${var.environment}"
////  role = "${var.iam_role}"
//
//  ports = <<EOF
//  [
//    {
//      "containerPort": ${var.container_port},
//      "hostPort": ${var.port}
//    }
//  ]
//EOF
//}

module "elb" {
  source = "./elb"

  name = "${var.name}"
  port = "${var.port}"
  environment = "${var.environment}"
  subnet_ids = "${var.subnet_ids}"
  external_dns_name = "${coalesce(var.external_dns_name, var.name)}"
  internal_dns_name = "${coalesce(var.internal_dns_name, var.name)}"
  healthcheck = "${var.healthcheck}"
  external_zone_id = "${var.external_zone_id}"
  internal_zone_id = "${var.internal_zone_id}"
  security_groups = "${var.security_groups}"
  log_bucket = "${var.log_bucket}"
  ssl_certificate_id = "${var.ssl_certificate_id}"
}