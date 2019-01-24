data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

resource "aws_s3_bucket" "codepipeline" {
  bucket = "${var.name}-${var.environment}-codepipeline-artifacts"

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket" "main" {
  bucket        = "${var.name}-deployments"
  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    Name        = "${var.name}"
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
  name       = "${var.name}-${var.environment}-cloudformation-role"
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


data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

data "aws_iam_policy_document" "worker_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "elasticloadbalancing.amazonaws.com",
        "codebuild.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "worker_policy_doc" {
  statement {
    resources = ["*"]
    actions = [
      "cloudformation:*",
      "elasticloadbalancing:*",
      "codebuild:*",
      "codepipeline:*",
      "s3:*",
      "ecs:*",
      "ecr:*",
      "iam:*",
      "lambda:*",
      "cloudwatch:*",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
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

resource "aws_iam_role" "worker" {
  name = "${var.name}-worker-role-deploy"
  assume_role_policy = "${data.aws_iam_policy_document.worker_assume_role_policy.json}"
}

resource "aws_iam_policy" "worker_policy" {
  name = "${var.name}-ecs-service-policy"
  policy = "${data.aws_iam_policy_document.worker_policy_doc.json}"
}

resource "aws_iam_role_policy_attachment" "worker_policy_attachment" {
  policy_arn = "${aws_iam_policy.worker_policy.arn}"
  role       = "${aws_iam_role.worker.id}"
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
        "cloudformation:*",
        "elasticloadbalancing:*",
        "codebuild:*",
        "codepipeline:*",
        "s3:*",
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
  name         = "${var.name}-${var.environment}-build"
  service_role = "${aws_iam_role.main.arn}"
  depends_on   = ["aws_iam_role.main"]

  "artifacts" {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:1.12.1"
    type            = "LINUX_CONTAINER"
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
      name  = "REPOSITORY_URI"
      value = "${var.ecr_repository_url}"
    }
    environment_variable {
      name = "ECS_SERVICE_NAME"
      value = "${var.name}"
    }
  }

  "source" {
    type = "CODEPIPELINE"

    buildspec = <<EOF
version: 0.2
phases:
  pre_build:
    commands:
      - $(aws ecr get-login)
      - echo $CODEBUILD_RESOLVED_SOURCE_VERSION
      - echo $CODEBUILD_INITIATOR
      - echo $CODEBUILD_SOURCE_VERSION
      - echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - echo $IMAGE_TAG
  build:
    commands:
      - docker build --tag "$${REPOSITORY_URI}:latest"  .
      - docker tag "$${REPOSITORY_URI}:latest" "$${REPOSITORY_URI}:$${IMAGE_TAG}"
  post_build:
    commands:
      - docker push "$REPOSITORY_URI:latest"
      - docker push "$${REPOSITORY_URI}:$${IMAGE_TAG}"
      - printf '[{"name":"%s","imageUri":"%s"}]' "$${ECS_SERVICE_NAME}" "$${REPOSITORY_URI}:$${IMAGE_TAG}" > imagedefinitions.json
artifacts:
  files: imagedefinitions.json
EOF
  }
}

resource "aws_ecs_service" "worker_service" {
  name            = "${var.name}-${var.environment}"
  cluster         = "${var.cluster}"
  desired_count   = "${var.desired_count}"
  task_definition = "${aws_ecs_task_definition.worker.arn}"
  launch_type     = "${var.launch_type}"
  network_configuration {
    subnets = ["${var.subnet_ids}"]
  }
  depends_on      = ["aws_ecs_task_definition.worker"]
}

data "template_file" "worker" {
  template = <<EOF
[
  {
    "Memory": ${var.memory},
    "MemoryReservation": ${var.memory_reservation},
    "Name": "${var.name}",
    "Image": "$${image}",
    "Essential": true,
    "LogConfiguration": {
      "LogDriver": "awslogs",
      "Options": {
        "awslogs-group": "$${awslogs_group}",
        "awslogs-region": "$${aws_region}",
        "awslogs-stream-prefix": "${var.environment}"
      },
    },
    "Environment": [
      {
        "Name": "Tag",
        "Value": "latest"
      },
      {
        "Name": "AWS_ACCOUNT_ID",
        "Value": "$${aws_account_id}"
      },
      {
        "Name": "AWS_REGION",
        "Value": "$${aws_region}"
      },
      {
        "Name": "AWS_ACCESS_KEY",
        "Value": "${var.aws_access_key}"
      },
      {
        "Name": "AWS_SECRET_KEY",
        "Value": "${var.aws_secret_key}"
      },
      {
        "Name": "ENVIRONMENT",
        "Value": "${var.environment}"
      }
    ]
  }
]
EOF

  vars {
    image          = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.ecr_name}:latest"
    awslogs_group  = "${aws_cloudwatch_log_group.main.name}"
    aws_region     = "${data.aws_region.current.name}"
    aws_account_id = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.name}-${var.environment}"
  container_definitions    = "${data.template_file.worker.rendered}"
  requires_compatibilities = ["${var.launch_type}"]
  memory                   = "${var.memory}"
  cpu                      = "${var.cpu}"
  depends_on               = ["data.template_file.worker"]
  network_mode             = "${var.network_mode}"
  task_role_arn            = "${aws_iam_role.worker.arn}"
  execution_role_arn       = "${aws_iam_role.worker.arn}"
}

resource "aws_codepipeline" "main" {
  name     = "${var.name}-${var.environment}-codepipeline"
  role_arn = "${aws_iam_role.main.arn}"

  "artifact_store" {
    location = "${aws_s3_bucket.codepipeline.bucket}"
    type     = "S3"
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
      run_order        = 1

      configuration {
        Owner      = "${var.source_owner}"
        Repo       = "${var.source_repo}"
        Branch     = "${var.source_branch}"
        OAuthToken = "${var.oauth_token}"
      }
    }
  }

  stage {
    name = "Build"

    "action" {
      category         = "Build"
      name             = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["app"]
      output_artifacts = ["imagedefinitions"]
      run_order        = 1

      configuration {
        ProjectName = "${var.name}-${var.environment}-build"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration {
        ClusterName = "${var.cluster}"
        ServiceName = "${aws_ecs_service.worker_service.name}"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
