variable "name" {}

variable "environment" {
  description = "Environment the spark EMR cluster will live"
}

variable "release" {
  description = "The release label for the Amazon EMR release"
  default = "emr-5.10.0"
}

variable "master_instance_type" {
  description = "The EC2 instance type of the master node. Exactly one of master_instance_type and instance_group must be specified."
  default = "m3.xlarge"
}

variable "service_role" {
  description = "IAM role that will be assumed by the Amazon EMR service to access AWS resources"
}

variable "security_configuration" {
  description = "The security configuration name to attach to the EMR cluster. Only valid for EMR clusters with release_label 4.8.0 or greater"
}

variable "core_instance_types" {
  description = "The EC2 instance type of the slave nodes. Cannot be specified if instance_groups is set"
  default = "m3.xlarge"
}

variable "core_instance_count" {
  description = "Number of Amazon EC2 instances used to execute the job flow. EMR will use one node as the cluster's master node and use the remainder of the nodes (core_instance_count-1) as core nodes. Cannot be specified if instance_groups is set. Default 1"
  default = 1
}

variable "key_name" {
  description = "Amazon EC2 key pair that can be used to ssh to the master node as the user called hadoop"
}

variable "subnet_id" {
  description = "VPC subnet id where you want the job flow to launch. Cannot specify the cc1.4xlarge instance type for nodes of a job flow launched in a Amazon VPC"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "bootstrap_action_path" {
  description = "Location of the script to run during a bootstrap action. Can be either a location in Amazon S3 or on a local file system"
  default = "s3://elasticmapreduce/bootstrap-actions/run-if"
}

variable "bootstrap_action_name" {
  description = "Name of the bootstrap action"
  default = "runif"
}

variable "bootstrap_action_args" {
  description = ""
  type = "list"
  default = ["instance.isMaster=true", "echo running on master node"]
}
