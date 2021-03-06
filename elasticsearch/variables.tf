variable "name" {
  description = "Domain name.  All lower-case.  a-z,0-9,- allowed."
}

variable "environment" {
}

variable "version" {
  description = "ElasticSearch version"
  default = "5.5"
}

variable "node_type" {
  description = "Instance type of data nodes in the cluster."
  default = "m4.large.elasticsearch"
}

variable "instance_count" {
  description = "Number of instances in the cluster."
  default = 2
}

variable "volume_size" {
  description = "Volume size per node (in GB)"
  default = 60
}

variable "dedicated_master_enabled" {
  description = "Indicates whether dedicated master nodes are enabled for the cluster."
  default = false
}

variable "dedicated_master_type" {
  description = "Instance type of the dedicated master nodes in the cluster."
  default = ""
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes in the cluster"
  default = 0
}

variable "zone_awareness_enabled" {
  description = "Indicates whether zone awareness is enabled."
  default = false
}

variable "zone_id" {
  description = "Route 53 zone to create service discovery CNAME in"
}

variable "security_group_ids" {
  description = "VPC Security Groups for the ES Cluster"
}

variable "subnet_ids" {
  description = "VPC Security Groups for the ES Cluster.  Use ONE subnet if zone awareness is disabled, TWO if it is enabled."
}
