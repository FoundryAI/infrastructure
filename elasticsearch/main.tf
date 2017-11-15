resource "aws_elasticsearch_domain" "main" {
  domain_name = "${var.name}"
  elasticsearch_version = "${var.version}"

  cluster_config {
    instance_type = "${var.node_type}"
    instance_count = "${var.instance_count}"
    dedicated_master_enabled = "${var.dedicated_master_enabled}"
    dedicated_master_count = "${var.dedicated_master_count}"
    dedicated_master_type = "${var.dedicated_master_type}"
    zone_awareness_enabled = "${var.zone_awareness_enabled}"
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = "${var.volume_size}"
  }

  vpc_options {
    security_group_ids = ["${split(",", var.security_group_ids)}"]
    subnet_ids = ["${split(",", var.subnet_ids)}"]
  }
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = "${aws_elasticsearch_domain.main.domain_name}"

  access_policies = <<POLICIES
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["*"]
      },
      "Action": [
        "es:*"
      ],
      "Resource": "${aws_elasticsearch_domain.main.arn}"
    }
  ]
}
POLICIES
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name = "${var.name}"
  type = "TXT"
  ttl = 300
  records = [
    "${aws_elasticsearch_domain.main.endpoint}"
  ]
}

resource "aws_ssm_parameter" "secret" {
  name = "/${var.environment}/common/ES_DOMAIN"
  value = "${aws_elasticsearch_domain.main.endpoint}"
  type  = "String"
}

