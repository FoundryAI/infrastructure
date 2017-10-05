data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

resource "aws_s3_bucket_object" "main" {
  bucket = "${aws_s3_bucket.main.bucket}"
  key = "templates.zip"

  // NOTE - YOU NEED TO REZIP TEMPLATES.ZIP ANYTIME YOU MAKE CHANGES TO ANY TEMPLATE SORRY IN ADVANCE!!! :( - NJG
  source = "${"${path.module}/templates/templates.zip"}"
}

resource "aws_s3_bucket" "codepipeline" {
  bucket = "${var.name}-${var.environment}-codepipeline-artifacts"

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.name}-deployments"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name = "${var.name}"

  tags {
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role" "main" {
  name = "${var.name}-${var.environment}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codepipeline.amazonaws.com",
          "codebuild.amazonaws.com",
          "cloudformation.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "cloudformation_execution" {
  name = "${var.name}-${var.environment}-cloudformation-role"
  depends_on = ["aws_iam_role.main"]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "cloudformation.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.main.arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "cloudformation_policy_attachment" {
  name       = "${var.name}-${var.environment}-cloudformation-policy-attachment"
  policy_arn = "${aws_iam_policy.cloudformation_policy.arn}"
  roles      = ["${aws_iam_role.main.id}", "${aws_iam_role.cloudformation_execution.id}"]
}

resource "aws_iam_policy" "cloudformation_policy" {
  name        = "${var.name}-${var.environment}-cloudformation-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CloudFormation"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "elasticloadbalancing:*",
        "codebuild:*",
        "codepipeline:*",
        "ecs:*",
        "ecr:*",
        "iam:*",
        "lambda:*"
      ]
    }
  ]
}
POLICY
}


resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "${var.name}-${var.environment}-codebuild-policy-attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles      = ["${aws_iam_role.main.id}"]
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "${var.name}-${var.environment}-codebuild-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<POLICY
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
        "logs:PutLogEvents"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.name}-${var.environment}-codepipeline-policy"
  role = "${aws_iam_role.main.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline.arn}",
        "${aws_s3_bucket.codepipeline.arn}/*",
        "${aws_s3_bucket.main.arn}",
        "${aws_s3_bucket.main.arn}/*"
      ]
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

resource "aws_codebuild_project" "main" {
  name = "${var.name}-${var.environment}-build"
  service_role = "${aws_iam_role.main.arn}"
  depends_on = ["aws_iam_role.main"]

  "artifacts" {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/docker:1.12.1"
    type         = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "ENVIRONMENT"
      "value" = "${var.environment}"
    }

    environment_variable {
      "name"  = "AWS_DEFAULT_REGION"
      "value" = "${data.aws_region.current.name}"
    }

    environment_variable {
      name = "REPOSITORY_URI"
      value = "${var.ecr_repository_url}"
    }
  }

  "source" {
    type = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.1
phases:
  pre_build:
    commands:
      - $(aws ecr get-login)
      - TAG="$([ $(echo $CODEBUILD_INITIATOR | cut -c 1-12) = codepipeline ] && echo $(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | head -c 8) || echo $(echo $CODEBUILD_SOURCE_VERSION | sed "s/\//\-/g"))"
  build:
    commands:
      - docker build --tag "$REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION" .
  post_build:
    commands:
      - docker push "$REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION"
      - printf '{"tag":"%s"}' $CODEBUILD_RESOLVED_SOURCE_VERSION > build.json
artifacts:
  files: build.json
EOF
  }
}

resource "aws_codepipeline" "main" {
  name = "${var.name}-${var.environment}-codepipeline"
  role_arn = "${aws_iam_role.main.arn}"

  "artifact_store" {
    location = "${aws_s3_bucket.codepipeline.bucket}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "App"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["app"]
      run_order = 1

      configuration {
        Owner      = "${var.source_owner}"
        Repo       = "${var.source_repo}"
        Branch     = "${var.source_branch}"
        OAuthToken = "${var.oauth_token}"
      }

    }

    action {
      name             = "Template"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["template"]
      run_order = 1

      configuration {
        S3Bucket   = "${aws_s3_bucket.main.bucket}"
        S3ObjectKey = "templates.zip"
      }

    }

  }

  stage {
    name = "Build"

    "action" {
      category = "Build"
      name = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["app"]
      output_artifacts = ["build"]
      run_order = 1

      configuration {
        ProjectName = "${var.name}-${var.environment}-build"
      }
    }
  }

  stage {
    name = "Deploy"

    "action" {
      category = "Deploy"
      name = "CreateChangeSet"
      owner = "AWS"
      provider = "CloudFormation"
      version = "1"
      input_artifacts = ["build", "template"]
      run_order = 1
      role_arn = "${aws_iam_role.cloudformation_execution.arn}"

      configuration {
        ChangeSetName = "${var.name}-${var.environment}-change-set"
        ActionMode = "CHANGE_SET_REPLACE"
        StackName = "${var.name}-${var.environment}-deployment-stack"
        Capabilities = "CAPABILITY_NAMED_IAM"
        TemplatePath = "template::ecs-service.yaml"
        ParameterOverrides = <<EOF
{
"AwsAccessKey": "${var.aws_access_key}",
"AwslogsGroup": "${aws_cloudwatch_log_group.main.name}",
"AwslogsStreamPrefix": "${var.environment}",
"AwsRegion": "${data.aws_region.current.name}",
"AwsSecretKey": "${var.aws_secret_key}",
"Cluster": "${var.cluster}",
"ContainerName": "${var.name}",
"Environment": "${var.environment}",
"DesiredCount": "${var.desired_count}",
"Name": "${var.name}",
"Tag" : "latest",
}
EOF
      }
    }

    "action" {
      category = "Deploy"
      name = "ExecuteChangeSet"
      owner = "AWS"
      provider = "CloudFormation"
      version = "1"
      role_arn = "${aws_iam_role.cloudformation_execution.arn}"
      run_order = 2

      configuration {
        ActionMode = "CHANGE_SET_EXECUTE"
        ChangeSetName = "${var.name}-${var.environment}-change-set"
        StackName = "${var.name}-${var.environment}-deployment-stack"
      }
    }
  }
}