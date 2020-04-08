/**
 * IAM Roles that go along with the CodeBuild/CodePipeline/ECS flow.
 * This is kept separate from the "service" module because it's rather verbose, but probably
 *   doesn't make much sense to use on its own.
 */

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
//  current = true
}

data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [ "codebuild.amazonaws.com", "ec2.amazonaws.com", "ecs.amazonaws.com" ]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [ "codepipeline.amazonaws.com" ]
    }
  }
}

data "aws_iam_policy_document" "ecs_service_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "elasticloadbalancing.amazonaws.com",
        "codebuild.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "codebuild_policy_doc" {
  statement {
    resources = ["*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "codebuild:*"
    ]
  }
  statement {
    resources = [
      "${var.artifact_bucket_arn}",
      "${var.artifact_bucket_arn}/*"
    ]
    actions = ["s3:*"]
  }
  statement {
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_name}"]
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
  }
}

data "aws_iam_policy_document" "codepipeline_policy_doc" {
  statement {
    resources = [
      "${var.artifact_bucket_arn}",
      "${var.artifact_bucket_arn}/*",
      "${var.deployment_bucket_arn}",
      "${var.deployment_bucket_arn}/*"
    ]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning"
    ]
  }

  statement {
    resources = ["*"]
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codepipeline:*",
      "lambda:*",
      "ecr:*",
      "ecs:*",
      "iam:PassRole"
    ]
  }
}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}


data "aws_iam_policy_document" "ecs_service_policy_doc" {
  statement {
    resources = ["*"]
    actions = [
      "elasticloadbalancing:*",
      "ec2:*",
      "ecr:*",
      "ecs:*"
    ]
  }

  statement {
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/${var.name}/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/common/*"
    ]
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
  }

  statement {
    resources = ["${data.aws_kms_alias.ssm.arn}"]
    actions = ["kms:Decrypt"]
  }

}

resource "aws_iam_role" "codebuild" {
  name = "${var.name}-codebuild-role"
  assume_role_policy = "${data.aws_iam_policy_document.codebuild_assume_role_policy.json}"
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.name}-codepipeline-role"
  assume_role_policy = "${data.aws_iam_policy_document.codepipeline_assume_role_policy.json}"
}

resource "aws_iam_role" "ecs_service" {
  name = "${var.name}-ecs-service-role-deploy"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_assume_role_policy.json}"
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "${var.name}-codebuild-policy"
  policy = "${data.aws_iam_policy_document.codebuild_policy_doc.json}"
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = "${var.name}-codepipeline-policy"
  policy = "${data.aws_iam_policy_document.codepipeline_policy_doc.json}"
}

resource "aws_iam_policy" "ecs_service_policy" {
  name = "${var.name}-ecs-service-policy"
  policy = "${data.aws_iam_policy_document.ecs_service_policy_doc.json}"
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  role       = "${aws_iam_role.codebuild.id}"
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  policy_arn = "${aws_iam_policy.codepipeline_policy.arn}"
  role       = "${aws_iam_role.codepipeline.id}"
}

resource "aws_iam_role_policy_attachment" "ecs_service_policy_attachment" {
  policy_arn = "${aws_iam_policy.ecs_service_policy.arn}"
  role       = "${aws_iam_role.ecs_service.id}"
}
