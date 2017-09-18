resource "aws_elasticache_replication_group" "main" {
  node_type = "${var.node_type}"
  port = "${var.port}"
  replication_group_description = "${var.name} cache replication group"
  replication_group_id = "${var.name}"
  automatic_failover_enabled = true
  parameter_group_name = "${var.parameter_group_name}"
  subnet_group_name = "${aws_elasticache_subnet_group.main.name}"
  cluster_mode {
    replicas_per_node_group = 1
    num_node_groups = "${var.num_cache_nodes}"
  }
  security_group_ids = ["${var.security_group_id}"]
}

resource "aws_elasticache_subnet_group" "main" {
  name = "${var.name}-cache-subnet"
  subnet_ids = [
    "${var.subnet_ids}"]
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name = "${var.name}"
  type = "CNAME"
  ttl = 300
  records = [
    "${aws_elasticache_replication_group.main.configuration_endpoint_address}"]
}
