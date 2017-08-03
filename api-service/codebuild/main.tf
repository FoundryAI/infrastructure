variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

variable "region" {
  description = "The name of the AWS region"
  default = "us-east-1"
}

variable "image" {
  description = "The image to run codebuild on"
}

variable "image_tag" {
  description = "Image tag to use"
  default = "latest"
}

variable "aws_profile" {
  description = "AWS profile to use"
  default = "default"
}

variable "repo_url" {
  description = "Repository url to load the source code from"
  default = ""
}

variable "rds_db_name" {
  description = "RDS DB name for running migrations (optional)"
  default = "N/A"
}

variable "rds_hostname" {
  description = "RDS DB hostname for running migrations (optional)"
  default = "N/A"
}

variable "rds_username" {
  description = "RDS DB username for running migrations (optional)"
  default = "N/A"
}

variable "rds_password" {
  description = "RDS DB password for running migrations (optional)"
  default = "N/A"
}

variable "environment_compute_type" {
  description = "Information about the compute resources the build project will use. Available values for this parameter are: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM or BUILD_GENERAL1_LARGE"
  default = "BUILD_GENERAL1_SMALL"
}

variable "migration_environment_compute_type" {
  description = "Information about the compute resources the build project will use. Available values for this parameter are: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM or BUILD_GENERAL1_LARGE"
  default = "BUILD_GENERAL1_SMALL"
}

variable "environment_image" {
  // https://docs.aws.amazon.com/codebuild/latest/userguide/create-project.html
  // https://hub.docker.com/r/jch254/dind-terraform-aws/
  description = "The ID of the Docker image to use for this build project"
  default = "aws/codebuild/docker:1.12.1"
}

variable "migration_environment_image" {
  description = "The ID of the Docker image to use for this build project"
  default = "node:8.2"
}

variable "environment_type" {
  description = "The type of build environment to use for related builds. The only valid value is LINUX_CONTAINER."
  default = "LINUX_CONTAINER"
}

variable "migration_environment_type" {
  description = "The type of build environment to use for related builds. The only valid value is LINUX_CONTAINER."
  default = "LINUX_CONTAINER"
}

variable "migration_buildspec" {
  description = "The migration buildspec to use"
  default = "buildspec.migration.yml"
}

variable "policy_arn" {
  description = "The codebuild policy arn for this stack"
}

variable "iam_role_id" {
  description = "The codebuild default iam role id"
}

variable "github_oauth_token" {
  description = "GitHub OAUTH token to use to retrieve code"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy_attachment" "default_codebuild_policy_attachment" {
  name = "codebuild-policy-attachment-${var.name}-${var.environment}"
  policy_arn = "${var.policy_arn}"
  roles = [
    "${var.iam_role_id}"]
}

resource "aws_codebuild_project" "main" {
  name = "${var.name}-${var.environment}"
  description = "codebuild project for ${var.name}"
  build_timeout = "5"
  service_role = "${var.iam_role_id}"

  "artifacts" {
    type = "CODEPIPELINE"
  }
  "environment" {
    compute_type = "${var.environment_compute_type}"
    image = "${var.environment_image}"
    type = "${var.environment_type}"
    # not available until 0.10.0 is released, need to manually set via codebuild dashbaord until then :(
    # https://github.com/terraform-providers/terraform-provider-aws/blob/master/aws/resource_aws_codebuild_project.go#L109
//    privileged_mode = true

    environment_variable {
      "name" = "AWS_REGION"
      "value" = "${var.region}"
    }

    environment_variable {
      "name" = "AWS_OUT"
      "value" = "json"
    }

    environment_variable {
      "name" = "AWS_PROF"
      "value" = "${var.aws_profile}"
    }

    environment_variable {
      "name" = "IMAGE_REPO_NAME"
      "value" = "${var.image}"
    }

    environment_variable {
      "name" = "IMAGE_TAG"
      "value" = "${var.image_tag}"
    }

    environment_variable {
      "name" = "AWS_ACCOUNT_ID"
      "value" = "${data.aws_caller_identity.current.account_id}"
    }

    environment_variable {
      name = "RDS_DB_NAME"
      value = "${var.rds_db_name}"
    }

    environment_variable {
      name = "RDS_HOSTNAME"
      value = "${var.rds_hostname}"
    }

    environment_variable {
      name = "RDS_USERNAME"
      value = "${var.rds_username}"
    }

    environment_variable {
      name = "RDS_PASSWORD"
      value = "${var.rds_password}"
    }

    environment_variable {
      name = "MYSQL_ROOT_PASSWORD"
      value = "${var.rds_password}"
    }

    environment_variable {
      name = "MYSQL_DATABASE"
      value = "${var.rds_db_name}"
    }

    environment_variable {
      name = "MYSQL_USER"
      value = "${var.rds_username}"
    }

    environment_variable {
      name = "MYSQL_PASSWORD"
      value = "${var.rds_password}"
    }
  }
  source {
    type = "CODEPIPELINE"
  }

  tags {
    "Name" = "${var.name}"
    "Environment" = "${var.environment}"
  }

}

resource "aws_codebuild_project" "migration" {
  name = "${var.name}-${var.environment}-migration"
  description = "codebuild migration project for ${var.name}"
  build_timeout = "25"
  service_role = "${var.iam_role_id}"

  "artifacts" {
    type = "NO_ARTIFACTS"
  }
  "environment" {
    compute_type = "${var.migration_environment_compute_type}"
    image = "${var.migration_environment_image}"
    type = "${var.migration_environment_type}"

    environment_variable {
      name = "RDS_DB_NAME"
      value = "${var.rds_db_name}"
    }

    environment_variable {
      name = "RDS_HOSTNAME"
      value = "${var.rds_hostname}"
    }

    environment_variable {
      name = "RDS_USERNAME"
      value = "${var.rds_username}"
    }

    environment_variable {
      name = "RDS_PASSWORD"
      value = "${var.rds_password}"
    }
  }

  "source" {
    type = "GITHUB"
    location = "${var.repo_url}"
    buildspec = "${var.migration_buildspec}"
    auth {
      type = "OAUTH"
      resource = "${var.github_oauth_token}"
    }
  }
}

// The ARN of the CodeBuild project.
output "id" {
  value = "${aws_codebuild_project.main.id}"
}

// A short description of the project.
output "description" {
  value = "${aws_codebuild_project.main.description}"
}

// The AWS Key Management Service (AWS KMS) customer master key (CMK) that was used for encrypting the build project's build output artifacts.
output "encryption_key" {
  value = "${aws_codebuild_project.main.encryption_key}"
}

// The projects name.
output "name" {
  value = "${aws_codebuild_project.main.name}"
}

output "migration_name" {
  value = "${aws_codebuild_project.migration.name}"
}

// The ARN of the IAM service role.
output "service_role" {
  value = "${aws_codebuild_project.main.service_role}"
}