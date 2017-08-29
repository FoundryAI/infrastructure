output "engine" {
  value = "${aws_elasticache_cluster.main.engine}"
}

output "engine_version" {
  value = "${aws_elasticache_cluster.main.engine_version}"
}

output "subnet_group_name" {
  value = "${aws_elasticache_cluster.main.subnet_group_name}"
}

output "cluster_address" {
  value = "${aws_elasticache_cluster.main.cluster_address}"
}

output "configuration_endpoint" {
  value = "${aws_elasticache_cluster.main.configuration_endpoint}"
}

output "node_type" {
  value = "${aws_elasticache_cluster.main.node_type}"
}

output "cache_nodes" {
  value = "${aws_elasticache_cluster.main.cache_nodes}"
}