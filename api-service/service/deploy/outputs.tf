output "name" {
  value = "${aws_lambda_function.main.function_name}"
}

output "arn" {
  value = "${aws_lambda_function.main.arn}"
}

output "role_arn" {
  value = "${aws_iam_role.main.arn}"
}
