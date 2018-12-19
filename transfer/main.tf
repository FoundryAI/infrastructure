variable "name" {
}

variable "environment" {
}

variable "account_id" {
}

resource "aws_kms_key" "transfer_s3_encrypt_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "transfer" {
  bucket = "${var.name}-${var.environment}-transfer"
  acl    = "private"

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
}
