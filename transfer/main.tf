variable "name" {
}

variable "environment" {
}

variable "account_id" {
}

data "template_file" "policy" {
  template = "${file("${path.module}/policy.json")}"

  vars = {
    bucket     = "${var.name}-${var.environment}-transfer"
    account_id = "${var.account_id}"
  }
}

resource "aws_s3_bucket" "transfer" {
  bucket = "${var.name}-${var.environment}-transfer"

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
  
  policy = "${data.template_file.policy.rendered}"
}
