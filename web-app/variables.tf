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