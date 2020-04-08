data "aws_caller_identity" "current" {}

data "aws_region" "current" {
//  current = true
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    resources = [ "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*" ]
    actions   = [ "lambda:InvokeFunction" ]
  }

  statement {
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    actions   = ["logs:*"]
  }

  statement {
    resources = ["*"]
    actions   = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
  }
}

data "archive_file" "slack_notifier" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/slack-notifier.zip"
}


resource "aws_iam_role" "main" {
  name = "${var.name}-slack-lambda-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

resource "aws_iam_policy" "main" {
  name        = "${var.name}-slack-lambda-policy"
  path        = "/service-role/"
  policy = "${data.aws_iam_policy_document.lambda_policy_doc.json}"
}

resource "aws_iam_role_policy_attachment" "main" {
  role = "${aws_iam_role.main.id}"
  policy_arn = "${aws_iam_policy.main.arn}"
}

resource "aws_lambda_function" "main" {
  function_name = "${var.name}-slack-notifier"
  handler = "main.send_post"
  role = "${aws_iam_role.main.arn}"
  runtime = "python2.7"
  memory_size = 128
  timeout = 5
  filename = "${path.module}/slack-notifier.zip"
  source_code_hash = "${data.archive_file.slack_notifier.output_base64sha256}"
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      WEBHOOK = "https://hooks.slack.com/services/${var.slack_webhook}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "pipeline_events" {
  name = "${var.name}-pipeline-events"
  description = "Capture build status changes in the pipeline"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.codepipeline"
  ],
  "detail-type": [
    "CodePipeline Pipeline Execution State Change"
  ],
  "resources": [
    "arn:aws:codepipeline:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.pipeline_name}"
  ],
  "detail": {
    "state": [
      "CANCELED",
      "FAILED",
      "SUCCEEDED",
      "SUPERSEDED",
      "RESUMED"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda" {
  arn = "${aws_lambda_function.main.arn}"
  rule = "${aws_cloudwatch_event_rule.pipeline_events.name}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id   = "AllowExecutionFromCloudWatch"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.main.function_name}"
  principal      = "events.amazonaws.com"
  source_arn     = "${aws_cloudwatch_event_rule.pipeline_events.arn}"
}
