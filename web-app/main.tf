resource "aws_s3_bucket" "main" {
  bucket = "${var.name}-${var.environment}"
  acl = "public-read"

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket" "codepipeline" {
  bucket = "${var.name}-${var.environment}-codepipeline-artifacts"

  tags {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name = "${var.domain_name}"
  type = "A"

  alias {
    evaluate_target_health = true
    name = "${aws_cloudfront_distribution.main.domain_name}"
    zone_id = "${aws_cloudfront_distribution.main.hosted_zone_id}"
  }
}

resource "aws_cloudfront_distribution" "main" {
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "${var.default_root_object}"
  aliases = ["${split(",", var.cloudfront_distribution_aliases)}"]

  "origin" {
    domain_name = "${aws_s3_bucket.main.bucket_domain_name}"
    origin_id = "S3-${var.name}-${var.environment}"
  }

  "logging_config" {
    include_cookies = false
    bucket = "${var.s3_logs_bucket}.s3.amazonaws.com"
    prefix = "cloudfront/${var.name}/${var.environment}"
  }

  "restrictions" {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }
  "default_cache_behavior" {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    default_ttl = 0
    max_ttl = 0
    min_ttl = 0

    "forwarded_values" {
      "cookies" {
        forward = "all"
      }
      query_string = true
    }
    target_origin_id = "S3-${var.name}-${var.environment}"
    viewer_protocol_policy = "redirect-to-https"
  }

  "viewer_certificate" {
    acm_certificate_arn = "${var.ssl_certificate_id}"
    minimum_protocol_version = "TLSv1"
    ssl_support_method = "sni-only"
  }

  "tags" {
    Name = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role" "main" {
  name = "${var.name}-${var.environment}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codepipeline.amazonaws.com",
          "codebuild.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "${var.name}-${var.environment}-codebuild-policy-attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles      = ["${aws_iam_role.main.id}"]
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "${var.name}-${var.environment}-codebuild-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.name}-${var.environment}-codepipeline-policy"
  role = "${aws_iam_role.main.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline.arn}",
        "${aws_s3_bucket.codepipeline.arn}/*",
        "${aws_s3_bucket.main.arn}",
        "${aws_s3_bucket.main.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "main" {
  name = "${var.name}-${var.environment}-build-deploy"
  service_role = "${aws_iam_role.main.arn}"
  depends_on = ["aws_iam_role.main"]

  "artifacts" {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "node:8.2"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "ENVIRONMENT"
      "value" = "${var.environment}"
    }
  }

  "source" {
    type = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.1
phases:
  pre_build:
    commands:
      - npm install
  build:
    commands:
      - ${var.codebuild_build_command}
  post_build:
    commands:
      - aws s3 sync --acl public-read s3://${aws_s3_bucket.main.bucket} ${var.build_path_to_deploy}
artifacts:
  type: zip
  files:
    - ${var.build_path_to_deploy}
EOF
  }
}

resource "aws_codepipeline" "main" {
  name = "${var.name}-${var.environment}-codepipeline"
  role_arn = "${aws_iam_role.main.arn}"

  "artifact_store" {
    location = "${aws_s3_bucket.codepipeline.bucket}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        Owner      = "${var.source_owner}"
        Repo       = "${var.source_repo}"
        Branch     = "${var.source_branch}"
        OAuthToken = "${var.github_oauth_token}"
      }

    }

  }

  stage {
    name = "DeployS3"

    "action" {
      category = "Build"
      name = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["source"]
      output_artifacts = ["build"]
      run_order = 1

      configuration {
        ProjectName = "${var.name}-${var.environment}-build-deploy"
      }
    }
  }
}