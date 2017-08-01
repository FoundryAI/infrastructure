variable "name" {
  description = "The name of the pipeline."
}

variable "role_arn" {
  description = "A service role Amazon Resource Name (ARN) that grants AWS CodePipeline permission to make calls to AWS services on your behalf."
}

variable "artifact_location" {
  description = "The location where AWS CodePipeline stores artifacts for a pipeline, such as an S3 bucket."
}

variable "artifact_type" {
  description = "The type of the artifact store, such as Amazon S3"
  default = "S3"
}

variable "artifact_name" {
  description = "Artifact name"
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

variable "codebuild_project_name" {
  description = "CodeBuild project name"
}

variable "codebuild_output_artifact" {
  description = "CodeBuild project output artifact to deploy"
}

resource "aws_codepipeline" "main" {
  name = "${var.name}"
  role_arn = "${var.role_arn}"
  "artifact_store" {
    location = "${var.artifact_location}"
    type = "${var.artifact_type}"
  }
  "stage" {
    name = "Source"
    "action" {
      category = "Source"
      name = "Source"
      owner = "ThirdParty"
      provider = "GitHub"
      version = "1"
      output_artifacts = ["${var.artifact_name}"]

      configuration {
        Owner = "${var.source_owner}"
        Repo = "${var.source_repo}"
        Branch = "${var.source_branch}"
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
      input_artifacts = ["${var.codebuild_output_artifact}"]
      version = "1"

      configuration {
        ProjectName = "${var.codebuild_project_name}"
      }
    }
  }
  // TODO - figure this out
//  "stage" {
//    name = "Deploy"
//    action {
//      category = "Deploy"
//      name = "Deploy"
//      owner = "AWS"
//      provider = "CloudFormation"
//      version = "1"
//
//      configuration {
//        StackName = ""
//      }
//    }
//  }
}

output "codepipeline_id" {
  value = "${aws_codepipeline.main.id}"
}

output "codepipeline_artifact_store" {
  value = "${aws_codepipeline.main.artifact_store}"
}