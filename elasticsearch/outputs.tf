output "id" {
  value = "${aws_elasticsearch_domain.main.domain_id}"
}

output "arn" {
  value = "${aws_elasticsearch_domain.main.arn}"
}

output "endpoint" {
  value = "${aws_elasticsearch_domain.main.endpoint}"
}
