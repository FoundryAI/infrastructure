variable "name" {
  description = "Default name to use for created resources"
}

variable "environment" {
  description = "Environment to locate created resources in"
}

variable "domain_name" {
  description = "Domain name record to create and point at the cloudfront distribution"
}

variable "source_owner" {
  description = "GitHub owner"
}

variable "source_repo" {
  description = "GitHub source repository to pull code from"
}

variable "github_oauth_token" {
  description = "GitHub OAuth token to use to pull source code down"
}

variable "source_branch" {
  description = "GitHub source branch to pull code from"
  default = "master"
}

variable "s3_logs_bucket" {
  description = "S3 bucket to store access logs in"
}

variable "default_root_object" {
  description = "The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL."
  default = "index.html"
}

variable "cloudfront_distribution_aliases" {
  description = "Extra CNAMEs (alternate domain names), if any, for this distribution. Comma separated."
  default = ""
}

variable "ssl_certificate_id" {
  description = "SSL ACM arn to use for the cloudfront distribution"
}

variable "zone_id" {
  description = "Route 53 domain zone ID to create the DNS record in"
}

variable "codebuild_prebuild_command" {
  description = "Command to have codebuild install the build project"
  default = "npm install"
}

variable "codebuild_build_command" {
  description = "Command to have codebuild run the build project"
  default = "npm run build"
}

variable "build_path_to_deploy" {
  description = "Root relative repository path to deploy to s3 bucket"
  default = "./public"
}