output "codepipeline_role_arn" {
  value = "${aws_iam_role.codepipeline.arn}"
}

output "codebuild_role_arn" {
  value = "${aws_iam_role.codebuild.arn}"
}

output "ecs_service_deployment_role_arn" {
  value = "${aws_iam_role.ecs_service.arn}"
}
