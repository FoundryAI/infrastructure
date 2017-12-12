variable service {}

variable environment {}

variable parameters {
  type = "map"
}

variable secrets {
  type = "map"
}

resource "aws_ssm_parameter" "string" {
  count = "${length(keys(var.parameters))}"

  overwrite = true
  name = "/${var.environment}/${var.service}/env/${element(keys(var.parameters), count.index)}"
  value = "${lookup(var.parameters, element(keys(var.parameters), count.index))}"
  type  = "String"
}

resource "aws_ssm_parameter" "secret" {
  count = "${length(keys(var.secrets))}"

  overwrite = true
  name = "/${var.environment}/${var.service}/env/${element(keys(var.secrets), count.index)}"
  value = "${lookup(var.secrets, element(keys(var.secrets), count.index))}"
  type  = "SecureString"
}
