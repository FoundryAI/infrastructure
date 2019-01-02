/**
 * This module is used to set configuration defaults for the AWS infrastructure.
 * It doesn't provide much value when used on its own because terraform makes it
 * hard to do dynamic generations of things like subnets, for now it's used as
 * a helper module for the stack.
 *
 * Usage:
 *
 *     module "defaults" {
 *       source = "stack/defaults"
 *       region = "us-east-1"
 *       cidr   = "10.0.0.0/16"
 *     }
 *
 */

variable "region" {
  description = "The AWS region"
}

variable "cidr" {
  description = "The CIDR block to provision for the VPC"
}

variable "default_ecs_ami" {
  default = {
    us-east-2      = "ami-037a92bf1efdb11a2"
    us-east-1      = "ami-0a6b7e0cc0b1f464f"
    us-west-2      = "ami-0c1f4871ebaae6d86"
    us-west-1      = "ami-0184f498956de7db5"
    eu-west-3      = "ami-0caadc4f0db31a303"
    eu-west-2      = "ami-0b5225210a12d9951"
    eu-west-1      = "ami-0acc9f8be17a41897"
    eu-central-1   = "ami-055aa9664ef169e25"
    ap-northeast-2 = "ami-0bdc871079baf9649"
    ap-northeast-1 = "ami-0c38293d60d98af86"
    ap-southeast-2 = "ami-0eed1c915ea891aca"
    ap-southeast-1 = "ami-0e28ff4e3f1776d86"
    ca-central-1   = "ami-02c80e9173258d289"
  }
}

# http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
# http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html#attach-bucket-policy
variable "default_log_account_ids" {
  default = {
    us-east-1      = "127311923021"
    us-east-1      = "033677994240"
    us-west-2      = "797873946194"
    us-west-1      = "027434742980"
    eu-west-1      = "156460612806"
    eu-central-1   = "054676820928"
    ap-southeast-1 = "114774131450"
    ap-northeast-1 = "582318560864"
    ap-southeast-2 = "783225319266"
    ap-northeast-2 = "600734575887"
    sa-east-1      = "507241528517"
    us-gov-west-1  = "048591011584"
    cn-north-1     = "638102146993"
  }
}

output "domain_name_servers" {
  value = "${cidrhost(var.cidr, 2)}"
}

output "ecs_ami" {
  value = "${lookup(var.default_ecs_ami, var.region)}"
}

output "s3_logs_account_id" {
  value = "${lookup(var.default_log_account_ids, var.region)}"
}
