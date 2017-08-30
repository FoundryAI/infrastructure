
resource "template_file" "install" {
  template = "${file("${path.module}/scripts/install.sh.tpl")}"

  vars {
    download_url  = "${var.download_url}"
    config        = "${var.config}"
    extra-install = "${var.extra_install}"
  }
}

// We launch Vault into an ASG so that it can properly bring them up for us.
resource "aws_autoscaling_group" "vault" {
  name = "vault-${aws_launch_configuration.vault.name}"
  launch_configuration = "${aws_launch_configuration.vault.name}"
  availability_zones = ["${split(",", var.availability_zones)}"]
  min_size = "${var.nodes}"
  max_size = "${var.nodes}"
  desired_capacity = "${var.nodes}"
  health_check_grace_period = 15
  health_check_type = "EC2"
  vpc_zone_identifier = ["${split(",", var.subnets)}"]
  load_balancers = ["${aws_elb.vault.id}"]

  tag {
    key = "Name"
    value = "vault-${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "vault" {
  name = "vault-${var.environment}"
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.vault.id}"]
  user_data = "${template_file.install.rendered}"
}

// Security group for Vault allows SSH and HTTP access (via "tcp" in
// case TLS is used)
resource "aws_security_group" "vault" {
  name = "vault-${var.environment}"
  description = "Vault servers for the ${var.environment} environment"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "vault-ssh" {
  security_group_id = "${aws_security_group.vault.id}"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

// This rule allows Vault HTTP API access to individual nodes, since each will
// need to be addressed individually for unsealing.
resource "aws_security_group_rule" "vault-http-api" {
  security_group_id = "${aws_security_group.vault.id}"
  type = "ingress"
  from_port = 8200
  to_port = 8200
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-egress" {
  security_group_id = "${aws_security_group.vault.id}"
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

// Launch the ELB that is serving Vault. This has proper health checks
// to only serve healthy, unsealed Vaults.
resource "aws_elb" "vault" {
  name = "vault-${var.environment}-elb"
  connection_draining = true
  connection_draining_timeout = 400
  internal = true
  subnets = ["${split(",", var.subnets)}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    instance_port = 8200
    instance_protocol = "tcp"
    lb_port = 80
    lb_protocol = "tcp"
  }

  listener {
    instance_port = 8200
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    target = "${var.elb_health_check}"
    interval = 15
  }
}

resource "aws_security_group" "elb" {
  name = "vault-${var.environment}-elb"
  description = "Vault ${var.environment} ELB"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "vault-elb-http" {
  security_group_id = "${aws_security_group.elb.id}"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-elb-https" {
  security_group_id = "${aws_security_group.elb.id}"
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-elb-egress" {
  security_group_id = "${aws_security_group.elb.id}"
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}