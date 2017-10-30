data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
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
      "ecs:*",
      "codepipeline:*",
      "s3:*",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
  }
}

data "archive_file" "ecs-deployer" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/ecs-deployer.zip"
}


resource "aws_iam_role" "main" {
  name = "${var.name}-ecs-deployer-lambda-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda-assume-role-policy.json}"
}

resource "aws_iam_policy" "main" {
  name        = "${var.name}-deployer-lambda-policy"
  path        = "/service-role/"
  policy = "${data.aws_iam_policy_document.lambda_policy_doc.json}"
}

resource "aws_iam_role_policy_attachment" "main" {
  role = "${aws_iam_role.main.id}"
  policy_arn = "${aws_iam_policy.main.arn}"
}

resource "aws_lambda_function" "main" {
  function_name = "${var.name}-ecs-deployer"
  handler = "main.deploy_handler"
  role = "${aws_iam_role.main.arn}"
  runtime = "python2.7"
  memory_size = 128
  timeout = 300
  filename = "${path.module}/ecs-deployer.zip"
  source_code_hash = "${data.archive_file.ecs-deployer.output_base64sha256}"
  tracing_config {
    mode = "Active"
  }
}
