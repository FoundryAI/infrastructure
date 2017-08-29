output "id" {
  value = "${aws_elasticache_replication_group.main.id}"
}

output "configuration_endpoint_address" {
  value = "${aws_elasticache_replication_group.main.configuration_endpoint_address}"
}