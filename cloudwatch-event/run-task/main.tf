resource "aws_iam_policy" "ecs_policy" {
  policy = "${data.aws_iam_policy_document.ecs_policy.json}"
}

data "aws_iam_policy_document" "ecs_policy" {
  statement {
    effect  = "Allow"
    actions = ["ECS:*"]
  }
}

resource "aws_iam_role" "ecs_role" {
  policy = "${aws_iam_policy.ecs_policy}"
}


resource "aws_cloudwatch_event_target" "event-target" {
  rule  = "${aws_cloudwatch_event_rule.event-rule.name}"
  arn   = "${var.event_target_arn}"
  role = "${aws_iam_role.ecs_role}"
  ecs_target {
    task_count = "${var.task_count}"
    task_definition_arn = "${var.task_definition_arn}"
  }
}

resource "aws_cloudwatch_event_rule" "event-rule" {
  name        = "${var.event_rule_name}"
  description = "${var.event_rule_description}"

  event_pattern = "${var.event_rule_pattern}"
}
