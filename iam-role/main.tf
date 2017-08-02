variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

resource "aws_iam_role" "default_codebuild_role" {
  name = "codebuild-role-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "codebuild.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "default_codepipeline_role" {
  name = "codepipeline-role-${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "cloudformation.amazonaws.com",
          "codepipeline.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "default_ecs_role" {
  name = "ecs-role-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "codepipeline.amazonaws.com",
          "ecs.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "default_codebuild_policy" {
  name = "codebuild-policy-${var.name}"
  path = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "s3:*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "default_codepipeline_policy" {
  name = "codepipeline-policy-${var.name}"
  role = "${aws_iam_role.default_codepipeline_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "cloudformation:*"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "default_ecs_service_role_policy" {
  name = "ecs-service-role-policy-${var.name}"
  role = "${aws_iam_role.default_ecs_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "default_ecs_instance_role_policy" {
  name = "ecs-instance-role-policy-${var.name}"
  role = "${aws_iam_role.default_ecs_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecs:StartTask",
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "default_ecs" {
  name = "ecs-instance-profile-${var.name}-${var.environment}"
  path = "/"
  role = "${aws_iam_role.default_ecs_role.name}"
}

output "default_codebuild_policy" {
  value = "${aws_iam_policy.default_codebuild_policy.id}"
}

output "default_codebuild_role_id" {
  value = "${aws_iam_role.default_codebuild_role.id}"
}

output "default_codepipeline_policy" {
  value = "${aws_iam_policy.default_codebuild_policy.id}"
}

output "default_codepipeline_role_id" {
  value = "${aws_iam_role.default_codepipeline_role.id}"
}

output "default_codepipeline_role_arn" {
  value = "${aws_iam_role.default_codepipeline_role.arn}"
}

output "default_ecs_role_id" {
  value = "${aws_iam_role.default_ecs_role.id}"
}

output "default_codebuild_arn" {
  value = "${aws_iam_role.default_codebuild_role.arn}"
}

output "arn" {
  value = "${aws_iam_role.default_ecs_role.arn}"
}

output "profile" {
  value = "${aws_iam_instance_profile.default_ecs.id}"
}