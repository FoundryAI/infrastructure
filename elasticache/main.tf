data "aws_elasticache_cluster" "main" {
  cluster_id = "${var.name}-cache"
}

resource "aws_elasticache_cluster" "main" {
  cluster_id = "${var.name}-cache"
  engine = "${var.engine}"
  node_type = "${var.node_type}"
  num_cache_nodes = "${var.num_cache_nodes}"
  port = "${var.port}"
  parameter_group_name = "${var.parameter_group_name}"
  subnet_group_name = "${aws_elasticache_subnet_group.main.name}"
}

resource "aws_elasticache_subnet_group" "main" {
  name = "${var.name}-cache-subnet"
  subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name = "${var.name}-cache"
  type = "CNAME"
  ttl = 300
  records = [
    "${data.aws_elasticache_cluster.main.cluster_address}"]
}