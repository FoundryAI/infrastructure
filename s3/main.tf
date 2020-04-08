variable "name" {
}

variable "environment" {
}

variable "log_bucket" {
  description = "S3 bucket ID to write S3 access logs into"
}

resource "aws_kms_key" "s3_encrypt_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "s3" {
  bucket = "${var.name}-${var.environment}"
  acl    = "private"

  logging {
    target_bucket = "${var.log_bucket}"
    target_prefix = "log/${var.name}-${var.environment}/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.s3_encrypt_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }

  versioning {
    enabled = true
  }
}
