variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "name" {
  description = "The service name, if empty the service name is defaulted to the image name"
  default = ""
}

variable "cluster" {
  description = "The cluster name or ARN"
}

variable "command" {
  description = "The raw json of the task command"
  default = "[]"
}

variable "desired_count" {
  description = "The desired count"
  default = 2
}

variable "launch_type" {
  description = "The desired launch type"
  default = "EC2"
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default = 10240
}

variable "memory_reservation" {
  description = "The number of MiB of memory to reserve for the container"
  default = 4096
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

variable "vpc_id" {
  description = "VPC ID to locate worker service in"
}
