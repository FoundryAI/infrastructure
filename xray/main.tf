resource "aws_instance" "xray" {
  ami = "ami-0080e4c5bc078760e"
  instance_type = "t2.small"

  key_name = "${var.environment}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = [
    "${aws_security_group.xray.id}"
  ]
  monitoring = true
  iam_instance_profile = "${aws_iam_instance_profile.xray.id}"
  user_data = "${file(format("%s/user_data.sh", path.module))}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  tags {
    Name = "xray-${var.environment}"
    Environment = "${var.environment}"
  }

}

resource "aws_security_group" "xray" {
  name = "${format("%s-internal-xray", var.environment)}"
  vpc_id = "${var.vpc_id}"
  description = "Allows internal xray & ssh traffic"

  ingress {
    from_port = 2000
    to_port = 2000
    protocol = "udp"
    cidr_blocks = [
      "${var.cidr}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${var.cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Name = "${format("%s internal xray", var.environment)}"
    Environment = "${var.environment}"
  }
}

data "aws_iam_policy_document" "xray_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "xray" {
  name = "${var.environment}-xray-role"
  assume_role_policy = "${data.aws_iam_policy_document.xray_assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_service_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  role       = "${aws_iam_role.xray.id}"
}

resource "aws_iam_instance_profile" "xray" {
  name = "xray-instance-profile-${var.environment}"
  path = "/"
  role = "${aws_iam_role.xray.name}"
}

resource "aws_route53_record" "xray" {
  name = "xray"
  type = "A"
  zone_id = "${var.dns_zone_id}"
  records = ["${aws_instance.xray.private_ip}"]
  ttl = 60
}
