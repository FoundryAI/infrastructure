variable "api_name" {
  description = "Name of the API gateway to create"
}

variable "api_endpoint" {
  description = "API endpoint"
}

variable "domain_zone_id" {
  description = "Default domain zone id to create API A record"
}

variable "ssl_certificate_id" {
  description = "SSL Certificate ID to use"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

resource "aws_route53_record" "main" {
  name = "${aws_api_gateway_domain_name.main.domain_name}"
  type = "A"
  zone_id = "${var.domain_zone_id}"

  alias {
    name = "${aws_api_gateway_domain_name.main.cloudfront_domain_name}"
    zone_id = "${aws_api_gateway_domain_name.main.cloudfront_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_api_gateway_resource" "health" {
  parent_id = "${aws_api_gateway_rest_api.main.root_resource_id}"
  path_part = "health"
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
}

resource "aws_api_gateway_method" "health" {
  authorization = "NONE"
  http_method = "GET"
  resource_id = "${aws_api_gateway_resource.health.id}"
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"

}

resource "aws_api_gateway_integration" "health" {
  depends_on = ["aws_api_gateway_method.health"]
  http_method = "${aws_api_gateway_method.health.http_method}"
  resource_id = "${aws_api_gateway_resource.health.id}"
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  type = "MOCK"
}

resource "aws_api_gateway_method_response" "200" {
  depends_on = ["aws_api_gateway_integration.health"]
  http_method = "${aws_api_gateway_method.health.http_method}"
  resource_id = "${aws_api_gateway_resource.health.id}"
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "200" {
  depends_on = ["aws_api_gateway_integration.health"]
  http_method = "${aws_api_gateway_method.health.http_method}"
  resource_id = "${aws_api_gateway_resource.health.id}"
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  status_code = "200"
}

resource "aws_api_gateway_deployment" "main" {
  depends_on = ["aws_api_gateway_integration.health"]
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name = "${var.environment}"

//  stage_description = "${timestamp()}" // forces to 'create' a new deployment each run - https://github.com/hashicorp/terraform/issues/6613
//  description = "Deployed at ${timestamp()}" // just some comment field which can be seen in deployment history


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.api_name}"
  description = "API resource for ${var.api_name} in the ${var.environment} environment"
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = "${aws_api_gateway_deployment.main.id}"
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name = "${var.environment}"
}

resource "aws_api_gateway_domain_name" "main" {
  domain_name = "${var.api_endpoint}"
  certificate_arn = "${var.ssl_certificate_id}"
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name = "${aws_api_gateway_deployment.main.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.main.domain_name}"
  base_path = "v1"
}

output "endpoint" {
  value = "${aws_api_gateway_domain_name.main.domain_name}"
}

// The ID of the associated REST API.
output "id" {
  value = "${aws_api_gateway_rest_api.main.id}"
}

// The name of the API stage.
output "stage" {
  value = "${aws_api_gateway_deployment.main.stage_name}"
}

//  The resource ID of the REST API's root
output "root_id" {
  value = "${aws_api_gateway_rest_api.main.root_resource_id}"
}