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

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name = "${var.environment}"

//  stage_description = "${timestamp()}" // forces to 'create' a new deployment each run - https://github.com/hashicorp/terraform/issues/6613
//  description = "Deployed at ${timestamp()}" // just some comment field which can be seen in deployment history

  //  depends_on = ["aws_api_gateway_method.main"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.api_name}"
  description = "API resource for ${var.api_name} in the ${var.environment} environment"
}

resource "aws_api_gateway_domain_name" "main" {
  domain_name = "${var.api_endpoint}"
  certificate_arn = "${var.ssl_certificate_id}"
}

resource "aws_api_gateway_base_path_mapping" "main" {
  api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name = "${var.environment}"
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