//-------------------------------------------------------------------
// Vault settings
//-------------------------------------------------------------------

variable "download_url" {
  default = "https://releases.hashicorp.com/vault/0.8.1/vault_0.8.1_linux_amd64.zip"
  description = "URL to download Vault"
}

variable "config" {
  description = "Configuration (text) for Vault"
}

variable "extra_install" {
  default = ""
  description = "Extra commands to run in the install script"
}

//-------------------------------------------------------------------
// AWS settings
//-------------------------------------------------------------------
variable "environment" {
  description = "Environment vault server is setup in"
}

variable "ami" {
  default = "ami-7eb2a716"
  description = "AMI for Vault instances"
}

variable "availability_zones" {
  default = "us-east-1a,us-east-1b"
  description = "Availability zones for launching the Vault instances"
}

variable "elb_health_check" {
  default = "HTTP:8200/v1/sys/health"
  description = "Health check for Vault servers"
}

variable "instance_type" {
  default = "m3.medium"
  description = "Instance type for Vault instances"
}

variable "key_name" {
  default = "default"
  description = "SSH key name for Vault instances"
}

variable "nodes" {
  default = "2"
  description = "number of Vault instances"
}

variable "subnets" {
  description = "list of subnets to launch Vault within"
}

variable "vpc_id" {
  description = "VPC ID"
}