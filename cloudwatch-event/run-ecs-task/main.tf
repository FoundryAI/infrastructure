data "aws_iam_policy_document" "ecs_policy" {
  statement {
    effect  = "Allow"
    actions = ["ECS:*"]
    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  assume_role_policy = "${data.aws_iam_policy_document.ecs_policy.json}"
}

resource "aws_cloudwatch_event_target" "event-target" {
  rule  = "${aws_cloudwatch_event_rule.event_rule.name}"
  arn   = "${var.event_target_arn}"
  role_arn = "${aws_iam_role.ecs_role.arn}"
  ecs_target {
    task_count = "${var.task_count}"
    task_definition_arn = "${var.task_definition_arn}"
  }
  depends_on = ["aws_cloudwatch_event_rule.event_rule"]
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  name        = "${var.event_rule_name}"
  description = "${var.event_rule_description}"

  event_pattern = "${var.event_rule_pattern}"
}
