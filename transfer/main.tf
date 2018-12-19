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

resource "aws_kms_key" "transfer_s3_encrypt_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "transfer" {
  bucket = "${var.name}-${var.environment}-transfer"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.transfer_s3_encrypt_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }

  versioning {
    enabled = true
  }
  
  policy = "${data.template_file.policy.rendered}"
}
