variable "region" {
  description = "The AWS region"
  default = "us-east-1"
}

variable "image" {
  description = "The docker image name, e.g nginx"
}

variable "image_repository_url" {
  description = "The repository url where the image is stored"
  default = ""
}

variable "name" {
  description = "The worker name, if empty the service name is defaulted to the image name"
}

/**
 * Optional Variables.
 */

variable "cpu" {
  description = "The number of cpu units to reserve for the container"
  default = 512
}

variable "env_vars" {
  description = "The raw json of the task env vars"
  default = "[]"
}
# [{ "name": name, "value": value }]

variable "command" {
  description = "The raw json of the task command"
  default = "[]"
}
# ["--key=foo","--port=bar"]

variable "entry_point" {
  description = "The docker container entry point"
  default = "[]"
}

variable "ports" {
  description = "The docker container ports"
  default = "[]"
}

variable "image_version" {
  description = "The docker image version"
  default = "latest"
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default = 512
}

variable "log_driver" {
  description = "The log driver to use use for the container"
  default = "awslogs"
}

variable "log_group" {
  description = "The log group to which the awslogs log driver will send its log streams"
  default = ""
}

variable "log_prefix" {
  description = "Associate a log stream with the specified prefix, the container name, and the ID of the Amazon ECS task to which the container belongs"
  default = ""
}

variable "role" {
  description = "The IAM Role to assign to the Container"
  default = ""
}
