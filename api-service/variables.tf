/**
 * Required Variables.
 */
variable "api_id" {
  description = "The ID of the REST API"
}

variable "api_root_id" {
  description = "The resource ID of the REST API's root"
}

variable "api_resource_name" {
  description = "The resource name to give this service"
}

variable "api_endpoint" {
  description = "the base api endpoint to set for the rest api"
}

variable "api_stage" {
  description = "The API stage"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "name" {
  description = "The service name, if empty the service name is defaulted to the image name"
  default = ""
}

variable "subnet_ids" {
  description = "Comma separated list of subnet IDs that will be passed to the ELB module"
}

variable "security_groups" {
  description = "Comma separated list of security group IDs that will be passed to the ELB module"
}

variable "port" {
  description = "The container host port"
}

variable "cluster" {
  description = "The cluster name or ARN"
}

variable "log_bucket" {
  description = "The S3 bucket ID to use for the ELB"
}

variable "ssl_certificate_id" {
  description = "SSL Certificate ID to use"
}

variable "iam_role" {
  description = "IAM Role ARN to use"
}

variable "external_dns_name" {
  description = "The subdomain under which the ELB is exposed externally, defaults to the task name"
  default = ""
}

variable "internal_dns_name" {
  description = "The subdomain under which the ELB is exposed internally, defaults to the task name"
  default = ""
}

variable "external_zone_id" {
  description = "The zone ID to create the record in"
}

variable "internal_zone_id" {
  description = "The zone ID to create the record in"
}

/**
 * Options.
 */

variable "healthcheck" {
  description = "Path to a healthcheck endpoint"
  default = "/health"
}

variable "container_port" {
  description = "The container port"
  default = 3000
}

variable "command" {
  description = "The raw json of the task command"
  default = "[]"
}

variable "desired_count" {
  description = "The desired count"
  default = 2
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default = 512
}

variable "cpu" {
  description = "The number of cpu units to reserve for the container"
  default = 512
}

variable "deployment_minimum_healthy_percent" {
  description = "lower limit (% of desired_count) of # of running tasks during a deployment"
  default = 100
}

variable "deployment_maximum_percent" {
  description = "upper limit (% of desired_count) of # of running tasks during a deployment"
  default = 200
}

variable "codebuild_iam_role_arn" {
  description = "Default codebuild iam role arn"
}

variable "codebuild_iam_role_role_id" {
  description = "Default codebuild iam role id"
}

variable "codebuild_policy" {
  description = "Default codebuild policy"
}

variable "codepipeline_role_arn" {
  description = "A service role Amazon Resource Name (ARN) that grants AWS CodePipeline permission to make calls to AWS services on your behalf."
}

variable "source_owner" {
  description = "GitHub repo organization"
  default = "FoundryAI"
}

variable "source_repo" {
  description = "GitHub source repository"
}

variable "source_branch" {
  description = "GitHub source branch"
  default = "master"
}

variable "oauth_token" {
  description = "GitHub oauth token"
}

variable "rds_db_name" {
  description = "RDS DB name for running migrations (optional)"
}

variable "rds_hostname" {
  description = "RDS DB hostname for running migrations (optional)"
}

variable "rds_username" {
  description = "RDS DB username for running migrations (optional)"
}

variable "rds_password" {
  description = "RDS DB password for running migrations (optional)"
}

variable "ecr_arn" {
  description = "ECR arn"
}

variable "ecr_name" {
  description = "ECR name"
}

variable "ecr_repository_url" {
  description = "ECR repository url"
}

variable "aws_access_key" {
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
}