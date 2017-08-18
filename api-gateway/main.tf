variable "api_id" {
  description = "The ID of the associated REST API."
}

variable "api_root_id" {
  description = ""
}

variable "api_endpoint" {
  description = "the base api endpoint to set for the rest api"
}

variable "api_stage" {
  description = "The API stage"
}

variable "elb_dns" {
  description = "The DNS hostname for the api elb"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

variable "region" {
  description = "The name of the AWS region"
  default = "us-east-1"
}

variable "resource_name" {
  description = "The API resource name"
}

variable "authorization" {
  description = "Authorization for the API gateway"
  default = "NONE"
}

variable "http_method" {
  description = "The HTTP method (GET, POST, PUT, DELETE, HEAD, OPTION, ANY) when calling the associated resource."
  default = "ANY"
}

variable "integration_type" {
  description = "The integration input's type (HTTP, MOCK, AWS, AWS_PROXY, HTTP_PROXY)"
  default = "HTTP_PROXY"
}

//resource "aws_api_gateway_deployment" "main" {
//  rest_api_id = "${var.api_id}"
//  stage_name = "${var.environment}"
//
//  stage_description = "${timestamp()}" // forces to 'create' a new deployment each run - https://github.com/hashicorp/terraform/issues/6613
//  description = "Deployed at ${timestamp()}" // just some comment field which can be seen in deployment history
//
////  depends_on = ["aws_api_gateway_method.main"]
//
//  lifecycle {
//    create_before_destroy = true
//  }
//}
//
//resource "aws_api_gateway_stage" "main" {
//  deployment_id = "${aws_api_gateway_deployment.main.id}"
//  rest_api_id = "${var.api_id}"
//  stage_name = "${var.environment}"
//}

resource "aws_api_gateway_method_settings" "main" {
//  depends_on = ["aws_api_gateway_deployment.main"]
  method_path = "*/*"
  rest_api_id = "${var.api_id}"
  stage_name = "${var.api_stage}"
  "settings" {
    metrics_enabled = true
    logging_level = "INFO"
  }
}

resource "aws_api_gateway_resource" "parent" {
  parent_id = "${var.api_root_id}"
  path_part = "${var.resource_name}"
  rest_api_id = "${var.api_id}"
}

resource "aws_api_gateway_resource" "child" {
  parent_id = "${aws_api_gateway_resource.parent.id}"
  path_part = "{proxy+}"
  rest_api_id = "${var.api_id}"
}

resource "aws_api_gateway_method" "default" {
  authorization = "${var.authorization}"
  http_method = "${var.http_method}"
  resource_id = "${aws_api_gateway_resource.parent.id}"
  rest_api_id = "${var.api_id}"
}

resource "aws_api_gateway_integration" "default" {
  integration_http_method = "${var.http_method}"
  http_method = "${aws_api_gateway_method.default.http_method}"
  resource_id = "${aws_api_gateway_resource.parent.id}"
  rest_api_id = "${var.api_id}"
  type = "${var.integration_type}"
  uri = "https://${var.elb_dns}" // TODO - figure out A record alias to support https
}

resource "aws_api_gateway_method" "main" {
  authorization = "${var.authorization}"
  http_method = "${var.http_method}"
  resource_id = "${aws_api_gateway_resource.child.id}"
  rest_api_id = "${var.api_id}"

  request_parameters {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "main" {
  integration_http_method = "${var.http_method}"
  http_method = "${aws_api_gateway_method.main.http_method}"
  resource_id = "${aws_api_gateway_resource.child.id}"
  rest_api_id = "${var.api_id}"
  type = "${var.integration_type}"
  uri = "http://${var.elb_dns}/{proxy}" // TODO - figure out A record alias to support https

  request_parameters {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

output "gateway_parent_resource_id" {
  value = "${aws_api_gateway_resource.parent.id}"
}

output "gateway_child_resource_id" {
  value = "${aws_api_gateway_resource.child.id}"
}

output "gateway_method_id" {
  value = "${aws_api_gateway_method.main.id}"
}

output "gateway_integration_id" {
  value = "${aws_api_gateway_integration.main.id}"
}