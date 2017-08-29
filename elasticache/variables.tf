variable "name" {
  description = "Group identifier. ElastiCache converts this name to lowercase"
}

variable "engine" {
  description = "Name of the cache engine to be used for this cache cluster. Valid values for this parameter are memcached or redis"
  default = "redis"
}

variable "node_type" {
  description = "The compute and memory capacity of the nodes. See Available Cache Node Types for supported node types"
  default = "cache.t2.small"
}

variable "port" {
  description = "The port number on which each of the cache nodes will accept connections. For Memcache the default is 11211, and for Redis the default port is 6379."
  default = 6379
}

variable "num_cache_nodes" {
  description = "The initial number of cache nodes that the cache cluster will have. For Redis, this value must be 1. For Memcache, this value must be between 1 and 20. If this number is reduced on subsequent runs, the highest numbered nodes will be removed."
  default = 1
}

variable "subnet_ids" {
  description = "IDs of the subnet to be used for the cache cluster."
  type = "list"
}

variable "parameter_group_name" {
  default = "default.redis3.2"
}

variable "zone_id" {
  description = "Route 53 zone to create service discovery CNAME in"
}