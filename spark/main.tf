resource "aws_iam_role_policy" "iam_emr_service_policy" {
  name = "iam_emr_service_policy_${var.environment}"
  role = "${aws_iam_role.iam_emr_spark_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CancelSpotInstanceRequests",
            "ec2:CreateNetworkInterface",
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:DeleteNetworkInterface",
            "ec2:DeleteSecurityGroup",
            "ec2:DeleteTags",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeInstances",
            "ec2:DescribeKeyPairs",
            "ec2:DescribeNetworkAcls",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribePrefixLists",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSpotInstanceRequests",
            "ec2:DescribeSpotPriceHistory",
            "ec2:DescribeSubnets",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeVpcEndpoints",
            "ec2:DescribeVpcEndpointServices",
            "ec2:DescribeVpcs",
            "ec2:DetachNetworkInterface",
            "ec2:ModifyImageAttribute",
            "ec2:ModifyInstanceAttribute",
            "ec2:RequestSpotInstances",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:RunInstances",
            "ec2:TerminateInstances",
            "ec2:DeleteVolume",
            "ec2:DescribeVolumeStatus",
            "ec2:DescribeVolumes",
            "ec2:DetachVolume",
            "iam:GetRole",
            "iam:GetRolePolicy",
            "iam:ListInstanceProfiles",
            "iam:ListRolePolicies",
            "iam:PassRole",
            "s3:CreateBucket",
            "s3:Get*",
            "s3:List*",
            "sdb:BatchPutAttributes",
            "sdb:Select",
            "sqs:CreateQueue",
            "sqs:Delete*",
            "sqs:GetQueue*",
            "sqs:PurgeQueue",
            "sqs:ReceiveMessage"
        ]
    }]
}
EOF
}

resource "aws_iam_role" "iam_emr_spark_profile_role" {
  name = "iam_emr_spark_profile_role_${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role" "iam_emr_spark_role" {
  name = "iam_emr_spark_role_${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_security_group" "main" {
  name = "${var.name}-${var.environment}"
  description = "Allow all inbound traffic to EMR spark"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = ["ingress", "egress"]
  }

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.name}-${var.environment}-logs"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_emr_cluster" "main" {
  name          = "${var.name}-${var.environment}"
  release_label = "${var.release}"
  applications  = ["Spark"]

  log_uri = "s3://${aws_s3_bucket.main.bucket_domain_name}/elasticmapreduce/"
  termination_protection = false
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    subnet_id                         = "${var.subnet_id}"
    service_access_security_group     = "${aws_security_group.main.id}"
    instance_profile                  = "${aws_iam_role.iam_emr_spark_profile_role.id}"
  }

  ebs_root_volume_size     = 100

  master_instance_type = "${var.master_instance_type}"
  core_instance_type   = "${var.core_instance_types}"
  core_instance_count  = "${var.core_instance_count}"

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }

  bootstrap_action {
    path = "${var.bootstrap_action_path}"
    name = "${var.bootstrap_action_name}"
    args = "${var.bootstrap_action_args}"
  }

//  configurations = "test-fixtures/emr_configurations.json"

  service_role = "${aws_iam_role.iam_emr_spark_role.arn}"
}

resource "aws_route53_record" "main" {
  zone_id = "${var.domain_zone_id}"
  name = "${var.name}"
  type = "TXT"
  ttl = 300
  records = [
    "${aws_emr_cluster.main.master_public_dns}"
  ]
}

resource "aws_ssm_parameter" "secret" {
  name = "/${var.environment}/common/EMR_SPARK_DOMAIN"
  value = "${aws_emr_cluster.main.master_public_dns}"
  type  = "String"
}
