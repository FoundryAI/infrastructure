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
}

variable "environment_compute_type" {
  description = "Information about the compute resources the build project will use. Available values for this parameter are: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM or BUILD_GENERAL1_LARGE"
  default = "BUILD_GENERAL1_SMALL"
}

variable "environment_image" {
  // https://docs.aws.amazon.com/codebuild/latest/userguide/create-project.html
  // https://hub.docker.com/r/jch254/dind-terraform-aws/
  description = "The ID of the Docker image to use for this build project"
  default = "jch254/dind-terraform-aws"
}

variable "environment_type" {
  description = "The type of build environment to use for related builds. The only valid value is LINUX_CONTAINER."
  default = "LINUX_CONTAINER"
}

variable "policy_arn" {
  description = "The codebuild policy arn for this stack"
}

variable "iam_role_id" {
  description = "The codebuild default iam role id"
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
    type = "NO_ARTIFACTS"
  }
  "environment" {
    compute_type = "${var.environment_compute_type}"
    image = "${var.environment_image}"
    type = "${var.environment_type}"
    privileged_mode = true

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
  }
  source {
    type = "GITHUB"
    location = "${var.repo_url}"
  }

  tags {
    "Name" = "${var.name}"
    "Environment" = "${var.environment}"
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

// The ARN of the IAM service role.
output "service_role" {
  value = "${aws_codebuild_project.main.service_role}"
}