variable "name" {
  description = "The name of the pipeline."
}

variable "environment" {
  description = "The environment of the pipeline"
}

variable "role_arn" {
  description = "A service role Amazon Resource Name (ARN) that grants AWS CodePipeline permission to make calls to AWS services on your behalf."
}

//variable "artifact_name" {
//  description = "Artifact name"
//}

variable "oauth_token" {
  description = "GitHub oauth token"
}

variable "source_owner" {
  description = "GitHub repo organization"
  default = "FoundryAI"
}

variable "source_repo" {
  description = "GitHub source repository"
}

variable "source_branch" {
  description = "GitHub source branch"
  default = "master"
}

variable "ecs_container_env_vars" {
  description = "Environment variables to set on the task definition"
}

variable "codebuild_project_name" {
  description = "CodeBuild project name"
}

variable "port" {
  description = "The container host port"
}

variable "cluster" {
  description = "The cluster name or ARN"
}

variable "container_port" {
  description = "The container port"
  default = 3000
}

variable "desired_count" {
  description = "The desired count"
  default = 2
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default = 512
}

variable "cpu" {
  description = "The number of cpu units to reserve for the container"
  default = 512
}

variable "repository_url" {
  description = "The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)"
}

variable "image_version" {
  description = "The docker image version"
  default = "latest"
}

variable "ecs_iam_role" {
  description = "The IAM Role associated with the task to run on deployment"
}

variable "elb_id" {
  description = "The ELB to associate the ecs service with upon deployment"
}

variable "codebuild_iam_role_role_id" {
  description = "Default codebuild iam role id"
}

//variable "codebuild_output_artifact" {
//  description = "CodeBuild project output artifact to deploy"
//}

data "aws_region" "current" {
  current = true
}

data "aws_caller_identity" "current" {}

data "template_file" "main" {
  template = "${file("${path.module}/template.json.tftemplate")}"

  vars {
    name = "${var.name}"
    cluster_name = "${var.cluster}"
    memory = "${var.memory}"
    cpu = "${var.cpu}"
    role_id = "${var.ecs_iam_role}"
    desired_count = "${var.desired_count}"
    container_name = "${var.name}"
    container_port = "${var.container_port}"
    port = "${var.port}"
    elb_id = "${var.elb_id}"
    repository_url = "${var.repository_url}"
    image_version = "${var.image_version}"
    container_env_vars = "${var.ecs_container_env_vars}"
  }
}

resource "aws_cloudformation_stack" "main" {
  name = "${var.name}-task-stack"
  iam_role_arn = "${var.role_arn}"
  template_body = "${data.template_file.main.rendered}"
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.name}-codepipline"
  acl = "private"

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_codepipeline" "main" {
  name = "${var.name}"
  role_arn = "${var.role_arn}"
  "artifact_store" {
    location = "${aws_s3_bucket.main.bucket}"
    type = "S3"
  }
  "stage" {
    name = "Source"
    "action" {
      category = "Source"
      name = "Source"
      owner = "ThirdParty"
      provider = "GitHub"
      version = "1"
      output_artifacts = ["${var.name}"]

      configuration {
        Owner = "${var.source_owner}"
        Repo = "${var.source_repo}"
        Branch = "${var.source_branch}"
        OAuthToken = "${var.oauth_token}"
      }
    }
  }
  "stage" {
    name = "Build"
    action {
      category = "Build"
      name = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      input_artifacts = ["${var.name}"]
      version = "1"

      configuration {
        ProjectName = "${var.codebuild_project_name}"
      }
    }
  }
// TODO - figure this out
//  "stage" {
//    name = "Test"
//    action {
//      category = "Deploy"
//      name = "Test"
//      owner = "AWS"
//      provider = "CloudFormation"
//      version = "1"
//
//      configuration {
//
//      }
//    }
//  }
  "stage" {
    name = "Deploy"
    action {
      category = "Deploy"
      name = "Deploy"
      owner = "AWS"
      provider = "CloudFormation"
      input_artifacts = ["${var.name}"]
      version = "1"

      configuration {
        ChangeSetName = "Deploy"
        ActionMode = "CREATE_UPDATE"
        StackName = "${aws_cloudformation_stack.main.id}"
        Capabilities = "CAPABILITY_NAMED_IAM"
        RoleArn = "${var.role_arn}"
      }
    }
  }
}

output "codepipeline_id" {
  value = "${aws_codepipeline.main.id}"
}

output "codepipeline_artifact_store" {
  value = "${aws_codepipeline.main.artifact_store}"
}