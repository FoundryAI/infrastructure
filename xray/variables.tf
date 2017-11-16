variable "environment" {
  description = "Microservice environment"
}

variable "dns_zone_id" {
  description = "DNS zone to create hostname for xray ec2 box"
}

variable "subnet_id" {
  description = "VPC subnet to place xray instance"
}

variable "vpc_id" {
}

variable "cidr" {
  description = "CIDR block to allow connections from"
}
