output "emr_cluster_id" {
  value = "${aws_emr_cluster.main.id}"
}

output "emr_cluster_name" {
  value = "${aws_emr_cluster.main.name}"
}

output "emr_public_dns" {
  value = "${aws_emr_cluster.main.master_public_dns}"
}

output "emr_cluster_role" {
  value = "${aws_emr_cluster.main.service_role}"
}
