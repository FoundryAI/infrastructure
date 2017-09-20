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

resource "aws_s3_bucket_object" "main" {
  bucket = "${aws_s3_bucket.main.bucket}"
  key = "templates.zip"

  // NOTE - YOU NEED TO REZIP TEMPLATES.ZIP ANYTIME YOU MAKE CHANGES TO ANY TEMPLATE SORRY IN ADVANCE!!! :( - NJG
  source = "${"${path.module}/templates/templates.zip"}"
}

resource "aws_s3_bucket_object" "slack" {
  bucket = "${aws_s3_bucket.main.bucket}"
  key = "slack-notifier.zip"

  // NOTE - YOU NEED TO REZIP SLACK-NOTIFIER.ZIP ANYTIME YOU MAKE CHANGES SORRY IN ADVANCE!!! :( - NJG
  source = "${"${path.module}/slack-notifier/slack-notifier.zip"}"
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.name}-deployments"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name = "${var.name}"

  tags {
    Environment = "${var.environment}"
  }
}

resource "aws_cloudformation_stack" "main" {
  name = "${var.name}-stack"
  template_body = "${file("${path.module}/templates/deployment-pipeline.yaml")}"
  capabilities = ["CAPABILITY_IAM"]
  iam_role_arn = "${var.codepipeline_role_arn}"

  parameters {
    GitHubRepo = "${var.source_repo}"
    GitHubBranch = "${var.source_branch}"
    GitHubToken = "${var.oauth_token}"
    GitHubUser = "${var.source_owner}"
    LoadBalancerName = "${module.alb.arn}"
    Cluster = "${var.cluster}"
    TemplateBucket = "${aws_s3_bucket.main.bucket}"
    Name = "${var.name}"
    ContainerName = "${var.name}"
    ContainerPort = "${var.port}"
    Port = "${var.port}"
    DesiredCount = "${var.desired_count}"
    LoadBalancerName = "${module.alb.target_group_arn}"
    Repository = "${var.ecr_name}"
    RdsDbName = "${var.rds_db_name}"
    RdsHostname = "${var.rds_hostname}"
    RdsUsername = "${var.rds_username}"
    RdsPassword = "${var.rds_password}"
    AwslogsGroup = "${aws_cloudwatch_log_group.main.name}"
    AwslogsStreamPrefix = "${var.environment}"
    DynamoDbEndpoint = "dynamodb.${data.aws_region.current.name}.amazonaws.com"
    SnsEndpoint = "sns.${data.aws_region.current.name}.amazonaws.com"
    AwsRegion = "${data.aws_region.current.name}"
    AwsAccessKey = "${var.aws_access_key}"
    AwsSecretKey = "${var.aws_secret_key}"
    Environment = "${var.environment}"
    SlackWebHook = "${var.slack_webhook}"
  }
}

resource "aws_cloudformation_stack" "deployment" {
  name = "${var.name}-deployment-stack"
  template_body = "${file("${path.module}/templates/ecs-service.yaml")}"
  capabilities = ["CAPABILITY_NAMED_IAM"]
  iam_role_arn = "${var.codepipeline_role_arn}"

  depends_on = [
    "module.alb"
  ]

  lifecycle {
    ignore_changes = [
      "parameters",
      "iam_role_arn"
    ]
  }

  parameters {
    AwsAccessKey = "${var.aws_access_key}"
    AwslogsGroup = "${aws_cloudwatch_log_group.main.name}"
    AwslogsStreamPrefix = "${var.environment}"
    AwsRegion = "${data.aws_region.current.name}"
    AwsSecretKey = "${var.aws_secret_key}"
    Cluster = "${var.cluster}"
    ContainerName = "${var.name}"
    ContainerPort = "${var.port}"
    Environment = "${var.environment}"
    DesiredCount = "${var.desired_count}"
    LoadBalancerName = "${module.alb.target_group_arn}"
    Name = "${var.name}"
    RdsDbName = "${var.rds_db_name}"
    RdsHostname = "${var.rds_hostname}"
    RdsUsername = "${var.rds_username}"
    RdsPassword = "${var.rds_password}"
    Repository = "sample"
    Tag = "latest"
    GitHubToken = "${var.oauth_token}"
  }
}


module "api_gateway" {
  source = "${path.module}/../api-gateway"
  environment = "${var.environment}"
  api_id = "${var.api_id}"
  api_root_id = "${var.api_root_id}"
  api_endpoint = "${var.api_endpoint}"
  api_stage = "${var.api_stage}"
  resource_name = "${var.api_resource_name}"
  elb_dns = "${module.alb.dns_name}"
}

module "alb" {
  source = "./alb"

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
  vpc_id = "${var.vpc_id}"
}
