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

# Gets the CURRENT task definition from AWS, reflecting anything that's been deployed outside
# of Terraform (ie. CodePipeline builds).
data "aws_ecs_task_definition" "task" {
  task_definition = "${aws_ecs_task_definition.main.family}"
  depends_on = ["aws_ecs_task_definition.main"]
}

# Gets the CURRENT container definition from AWS.  This allows us to fully reconstruct
# the task definition deployed by CodePipeline.
# TODO: Figure out how to make this work.
//data "aws_ecs_container_definition" "task" {
//  task_definition = "${data.aws_ecs_task_definition.task.id}"
//  container_name  = "${var.name}"
//}

data "aws_ecr_repository" "main" {
  name = "${var.ecr_name}"
}

data "aws_ecr_repository" "sample" {
  name = "${var.ecr_name}"
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

// If you change the task definition, the sample image will be redeployed.
// Take care to re-run the pipeline to redeploy the application with an
// actual image.
resource "aws_ecs_task_definition" "main" {
  family = "${var.name}"
  task_role_arn = "${module.iam_roles.ecs_service_deployment_role_arn}"

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.name}",
    "image": "${data.aws_ecr_repository.sample.repository_url}/sample:latest",
    "essential": true,
    "cpu": ${var.cpu},
    "memory": ${var.memory},
    "portMappings": [{
      "containerPort": ${var.container_port},
      "hostPort": 0
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.main.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "${var.environment}"
      }
    },
    "environment": [
      {
        "name": "RDS_DB_NAME",
        "value": "${var.rds_db_name}"
      },
      {
        "name": "RDS_HOSTNAME",
        "value": "${var.rds_hostname}"
      },
      {
        "name": "RDS_USERNAME",
        "value": "${var.rds_username}"
      },
      {
        "name": "RDS_PASSWORD",
        "value": "${var.rds_password}"
      },
      {
        "name": "DYNAMODB_ENDPOINT",
        "value": "dynamodb.us-east-1.amazonaws.com"
      },
      {
        "name": "SNS_ENDPOINT",
        "value": "sns.us-east-1.amazonaws.com"
      },
      {
        "name": "AWS_ACCOUNT_ID",
        "value": "${data.aws_caller_identity.current.account_id}"
      },
      {
        "name": "AWS_REGION",
        "value": "${data.aws_region.current.name}"
      },
      {
        "name": "AWS_ACCESS_KEY",
        "value": "${var.aws_access_key}"
      },
      {
        "name": "AWS_SECRET_KEY",
        "value": "${var.aws_secret_key}"
      },
      {
        "name": "ENVIRONMENT",
        "value": "${var.environment}"
      },
      {
        "name": "PORT",
        "value": "${var.port}"
      },
      {
        "name": "GITHUB_OAUTH_TOKEN",
        "value": "${var.oauth_token}"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name = "${var.name}"
  cluster = "${var.cluster}"
  desired_count = 2
  task_definition = "${aws_ecs_task_definition.main.family}:${max("${aws_ecs_task_definition.main.revision}", "${data.aws_ecs_task_definition.task.revision}")}"
  iam_role = "${module.iam_roles.ecs_service_deployment_role_arn}"

  load_balancer {
    target_group_arn = "${module.alb.target_group_arn}"
    container_name = "${var.name}"
    container_port = "${var.container_port}"
  }

  depends_on = ["module.iam_roles"]
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
      value = "${data.aws_ecr_repository.main.repository_url}"
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
      value = "${data.aws_ecr_repository.main.repository_url}"
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
  depends_on = ["aws_ecs_task_definition.main"]

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
      category = "Invoke"
      name = "ECS_Deploy"
      owner = "AWS"
      provider = "Lambda"
      version = "1"

      input_artifacts = ["BuildOutput"]
      output_artifacts = []
      run_order = "1"
      configuration {
        FunctionName = "${module.deploy_lambda.name}"
        UserParameters = <<EOF
{
  "cluster": "${var.cluster}",
  "task": "${aws_ecs_task_definition.main.family}",
  "service": "${aws_ecs_service.main.name}",
  "role": "${module.iam_roles.ecs_service_deployment_role_arn}",
  "region": "${data.aws_region.current.name}",
  "aws_access_key_id": "${var.aws_access_key}",
  "aws_secret_key": "${var.aws_secret_key}",
  "image": "${data.aws_ecr_repository.main.repository_url}"
}
EOF
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

module "deploy_lambda" {
  source = "./deploy"
  name = "${var.name}"
}

module "iam_roles" {
  source = "./ci-iam"
  name = "${var.name}"
  ecr_name = "${var.ecr_name}"
  artifact_bucket_arn = "${aws_s3_bucket.artifacts.arn}"
  deployment_bucket_arn = "${aws_s3_bucket.main.arn}"
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

