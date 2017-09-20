output "s3_bucket" {
  value = "${aws_s3_bucket.main.bucket}"
}

output "s3_bucket_domain_name" {
  value = "${aws_s3_bucket.main.bucket_domain_name}"
}

output "cloudfront_distribution_id" {
  value = "${aws_cloudfront_distribution.main.id}"
}

output "cloudfront_distribution_arn" {
  value = "${aws_cloudfront_distribution.main.arn}"
}

output "cloudfront_distribution_domain_name" {
  value = "${aws_cloudfront_distribution.main.domain_name}"
}

output "cloudfront_distribution_hosted_zone_id" {
  value = "${aws_cloudfront_distribution.main.hosted_zone_id}"
}