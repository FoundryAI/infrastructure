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
    "geo_restriction" {
      restriction_type = "blacklist"
    }
  }
  "default_cache_behavior" {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = []
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
  name = "${var-name}-${var.environment}-codepipeline-policy"
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
  name = "${var.name}-${var.environment}-build"

  "artifacts" {
    type = "S3"
    location = "${aws_s3_bucket.main.bucket}"
    namespace_type = "BUILD_ID"
    packaging = "NONE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "2"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "ENVIRONMENT"
      "value" = "${var.environment}"
    }
  }

  "source" {
    type = "CODEPIPELINE"
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
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"

      configuration {
        ProjectName = "${var.name}-${var.environment}-build"
      }
    }
  }
}