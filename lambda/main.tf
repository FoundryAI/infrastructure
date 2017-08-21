resource "aws_lambda_function" "main" {
  function_name = ""
  handler = ""
  role = ""
  runtime = ""
}

resource "aws_iam_role" "main" {
  name = "${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}