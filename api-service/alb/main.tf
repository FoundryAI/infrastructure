resource "aws_alb" "main" {
  name = "${var.name}-alb"
  internal = "${var.internal}"
  subnets = [
    "${split(",", var.subnet_ids)}"]
  security_groups = [
    "${split(",",var.security_groups)}"]

  enable_deletion_protection = false

  access_logs {
    bucket = "${var.log_bucket}"
    prefix = "${var.name}-alb"
  }

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = "${aws_alb.main.arn}"
  port = 80
  protocol = "HTTP"

  default_action = {
    target_group_arn = "${aws_alb_target_group.main.arn}"
    type = "forward"
  }
}

resource "aws_alb_listener_rule" "main" {
  listener_arn = "${aws_alb_listener.main.arn}"
  priority = 1
  "action" {
    target_group_arn = "${aws_alb_target_group.main.arn}"
    type = "forward"
  }
  "condition" {
    field = "path-pattern"
    values = ["/"]
  }
}

resource "aws_alb_target_group" "main" {
  name = "${var.name}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = "${var.vpc_id}"
  deregistration_delay = 90

  health_check {
    matcher  = "200"
    interval = 30
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    path = "${var.healthcheck}"
  }
}

resource "aws_route53_record" "internal" {
  zone_id = "${var.internal_zone_id}"
  name = "${coalesce(var.internal_dns_name, "${var.name}-alb")}"
  type = "A"

  alias {
    evaluate_target_health = false
    name = "${aws_alb.main.dns_name}"
    zone_id = "${aws_alb.main.zone_id}"
  }
}
