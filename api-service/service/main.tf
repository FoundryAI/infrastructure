/**
 * Creates a load-balanced Docker service in an ECS cluster.
 *
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "stack/api-service"
 *        name      = "auth-api-service"
 *        cluster   = "default"
 *      }
 *
 */

/**
 * Resources.
 */

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

data "archive_file" "templates" {
  type        = "zip"
  source_dir  = "${path.module}/templates"
  output_path = "${path.module}/templates.zip"
}

resource "aws_s3_bucket_object" "main" {
  bucket = "${aws_s3_bucket.main.bucket}"
  key = "templates.zip"
  etag = "${data.archive_file.templates.output_md5}"

  source = "${"${path.module}/templates.zip"}"
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

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.name}-codepipeline-artifacts"
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



resource "aws_codebuild_project" "build" {
  name = "${var.name}-build"
  service_role = "${module.iam_roles.codebuild_role_arn}"

  artifacts {
    type = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/docker:1.12.1"
    type = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = "${data.aws_region.current.name}"
    }

    environment_variable {
      name = "REPOSITORY_URI"
      value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.ecr_name}"
    }
  }

  source {
    type = "GITHUB"
    location = "https://github.com/FoundryAI/${var.source_repo}.git"
    buildspec = <<EOF
version: 0.2
phases:
  pre_build:
    commands:
      - $(aws ecr get-login)
      - TAG="$([ $(echo $CODEBUILD_INITIATOR | cut -c 1-12) = codepipeline ] && echo $(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | head -c 8) || echo $(echo $CODEBUILD_SOURCE_VERSION | sed "s/\//\-/g"))"
  build:
    commands:
      - docker build --tag "$${REPOSITORY_URI}:$${TAG}" .
  post_build:
    commands:
      - docker push "$${REPOSITORY_URI}:$${TAG}"
      - printf '{"tag":"%s"}' $TAG > build.json
artifacts:
  files: build.json
EOF
  }
}

resource "aws_codebuild_project" "test" {
  name = "${var.name}-test"
  service_role = "${module.iam_roles.codebuild_role_arn}"

  artifacts {
    type = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/docker:1.12.1"
    type = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = "${data.aws_region.current.name}"
    }

    environment_variable {
      name = "REPOSITORY_URI"
      value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.ecr_name}"
    }
  }

  source {
    type = "GITHUB"
    location = "https://github.com/FoundryAI/${var.source_repo}.git"
    buildspec = <<EOF
version: 0.2
phases:
  pre_build:
    commands:
      - curl -L "https://github.com/docker/compose/releases/download/1.15.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
      - TAG="$([ $(echo $CODEBUILD_INITIATOR | cut -c 1-12) = codepipeline ] && echo $(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | head -c 8) || echo $(echo $CODEBUILD_SOURCE_VERSION | sed "s/\//\-/g"))"
      - docker network create hud_ai_local
  build:
    commands:
      - touch .env
      - docker-compose -f docker-compose.yml -f docker-compose.test.yml run api || (docker-compose -f docker-compose.yml -f docker-compose.test.yml logs && false)
  post_build:
    commands:
      - printf '{"tag":"%s"}' $TAG > build.json
artifacts:
  files: build.json
EOF
  }
}

resource "aws_codepipeline" "main" {
  name = "${var.name}-codepipeline"
  role_arn = "${module.iam_roles.codepipeline_role_arn}"
  depends_on = [ "aws_cloudformation_stack.deployment" ]

  artifact_store {
    location = "${aws_s3_bucket.artifacts.bucket}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      name = "App"
      owner = "ThirdParty"
      provider = "GitHub"
      version = "1"
      run_order = "1"
      output_artifacts = ["App"]

      configuration {
        Owner = "${var.source_owner}"
        Repo = "${var.source_repo}"
        Branch = "${var.source_branch}"
      }
    }

    action {
      name = "Template"
      category = "Source"
      owner = "AWS"
      provider = "S3"
      version = "1"
      run_order = "1"
      output_artifacts = ["Template"]

      configuration {
        S3Bucket = "${aws_s3_bucket.main.bucket}"
        S3ObjectKey = "templates.zip"
      }
    }
  }

  stage {
    name = "BuildTest"

    action {
      category = "Build"
      name = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.build.name}"
      }

      input_artifacts = ["App"]
      output_artifacts = ["BuildOutput"]
      run_order = "1"
    }

    action {
      category = "Build"
      name = "Test"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.test.name}"
      }

      input_artifacts = ["App"]
      output_artifacts = ["TestOutput"]
      run_order = "1"
    }
  }

  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      name = "CreateChangeSet"
      owner = "AWS"
      provider = "CloudFormation"
      version = "1"
      run_order = "1"
      input_artifacts = ["Template", "BuildOutput"]

      configuration {
        ChangeSetName = "${var.name}-change-set"
        ActionMode = "CHANGE_SET_REPLACE"
        StackName = "${aws_cloudformation_stack.deployment.name}"
        Capabilities = "CAPABILITY_NAMED_IAM"
        TemplatePath = "Template::ecs-service.yaml"
        RoleArn = "${module.iam_roles.cloudformation_deployment_role_arn}"
        ParameterOverrides = <<EOF
{
  "AwsAccessKey": "${var.aws_access_key}",
  "AwslogsGroup": "${aws_cloudwatch_log_group.main.name}",
  "AwslogsStreamPrefix": "${var.environment}",
  "AwsRegion": "${data.aws_region.current.name}",
  "AwsSecretKey": "${var.aws_secret_key}",
  "Cluster": "${var.cluster}",
  "ContainerName": "${var.name}",
  "ContainerPort": "${var.port}",
  "Environment": "${var.environment}",
  "DesiredCount": "${var.desired_count}",
  "LoadBalancerName": "${module.alb.target_group_arn}",
  "Name": "${var.name}",
  "RdsDbName": "${var.rds_db_name}",
  "RdsHostname": "${var.rds_hostname}",
  "RdsUsername": "${var.rds_username}",
  "RdsPassword": "${var.rds_password}",
  "Repository": "${var.ecr_name}",
  "Tag" : { "Fn::GetParam" : [ "BuildOutput", "build.json", "tag" ] },
  "GitHubToken": "${var.oauth_token}",
  "EcsRoleArn": "${module.iam_roles.ecs_service_deployment_role_arn}",
  "Memory": "${var.memory}",
  "Cpu": "${var.cpu}"
}
EOF
      }
    }

    action {
      category = "Deploy"
      name = "ExecuteChangeSet"
      owner = "AWS"
      provider = "CloudFormation"
      version = "1"
      run_order = "2"

      configuration {
        ActionMode = "CHANGE_SET_EXECUTE"
        ChangeSetName = "${var.name}-change-set"
        RoleArn= "${module.iam_roles.cloudformation_deployment_role_arn}"
        StackName = "${aws_cloudformation_stack.deployment.name}"
      }
    }
  }
}

module "slack_notifier" {
  source = "./slack-notifier"
  name = "${var.name}"
  pipeline_name = "${aws_codepipeline.main.name}"
  slack_webhook = "${var.slack_webhook}"
}

module "iam_roles" {
  source = "./ci-iam"
  name = "${var.name}"
  ecr_name = "${var.ecr_name}"
  artifact_bucket_arn = "${aws_s3_bucket.artifacts.arn}"
  deployment_bucket_arn = "${aws_s3_bucket.main.arn}"
}

resource "aws_cloudformation_stack" "deployment" {
  name = "${var.name}-deployment-stack"
  template_body = "${file("${path.module}/templates/ecs-service.yaml")}"
  capabilities = ["CAPABILITY_NAMED_IAM"]
  iam_role_arn = "${module.iam_roles.cloudformation_deployment_role_arn}"

  depends_on = [
    "module.alb"
  ]

  lifecycle {
    ignore_changes = [
      "parameters"
    ]
  }

  on_failure = "DELETE"

  parameters {
    AwsAccessKey = "${var.aws_access_key}"
    AwslogsGroup = "${aws_cloudwatch_log_group.main.name}"
    AwslogsStreamPrefix = "${var.environment}"
    AwsRegion = "${data.aws_region.current.name}"
    AwsSecretKey = "${var.aws_secret_key}"
    Cluster = "${var.cluster}"
    ContainerName = "${var.name}"
    ContainerPort = "${var.port}"
    Environment = "${var.environment}"
    DesiredCount = "${var.desired_count}"
    LoadBalancerName = "${module.alb.target_group_arn}"
    Name = "${var.name}"
    RdsDbName = "${var.rds_db_name}"
    RdsHostname = "${var.rds_hostname}"
    RdsUsername = "${var.rds_username}"
    RdsPassword = "${var.rds_password}"
    Repository = "sample"
    Tag = "latest"
    GitHubToken = "${var.oauth_token}"
    EcsRoleArn = "${module.iam_roles.ecs_service_deployment_role_arn}"
    Memory = "${var.memory}"
    Cpu = "${var.cpu}"
  }
}

module "alb" {
  source = "../alb"

  name = "${var.name}"
  port = "${var.port}"
  internal = "${var.internal_alb}"
  environment = "${var.environment}"
  subnet_ids = "${var.subnet_ids}"
  internal_dns_name = "${coalesce(var.internal_dns_name, "${var.name}-alb")}"
  healthcheck = "${var.healthcheck}"
  internal_zone_id = "${var.internal_zone_id}"
  security_groups = "${var.security_groups}"
  log_bucket = "${var.log_bucket}"
  ssl_certificate_id = "${var.ssl_certificate_id}"
  vpc_id = "${var.vpc_id}"
}

