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

variable "ecs_task_definition_id" {
  description = "The ECS task definition to deploy upon successful build"
}

variable "codebuild_project_name" {
  description = "CodeBuild project name"
}

//variable "codebuild_output_artifact" {
//  description = "CodeBuild project output artifact to deploy"
//}

data "template_file" "main" {
  template = "${file("../api-service/cloudformation/template.json")}"

  vars {
    Tag = ""
    COOKIE_SECRET = ""
    RDS_DB_NAME = ""
    RDS_HOSTNAME = ""
    RDS_PASSWORD = ""
  }
}

resource "aws_cloudformation_stack" "main" {
  name = "${var.name}-deploy-stack"

  template_url = "../api-service/cloudformation/template.yaml"
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
        StackName = "${var.name}-${var.environment}"
        Capabilities = "CAPABILITY_NAMED_IAM"
        TemplatePath = "${aws_cloudformation_stack.main.template_url}"
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