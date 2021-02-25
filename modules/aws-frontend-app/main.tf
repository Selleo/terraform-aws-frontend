locals {
  origin_id = "main"
}

resource "aws_cloudfront_distribution" "this" {
  comment             = var.comment
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object
  aliases             = var.aliases
  price_class         = var.price_class

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.certificate_arn
    minimum_protocol_version       = var.certificate_minimum_protocol_version

    # sni-only is preferred, vip causes CloudFront to use a dedicated IP address and may incur extra charges.
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-cloudfront-distribution-origin.html

    origin_id   = local.origin_id # must be unique within distribution
    origin_path = var.s3_origin.path
    domain_name = var.s3_origin.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = var.default_cache_behavior.allowed_methods
    cached_methods   = var.default_cache_behavior.cached_methods
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress               = var.default_cache_behavior.compress
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.default_cache_behavior.min_ttl
    default_ttl            = var.default_cache_behavior.default_ttl
    max_ttl                = var.default_cache_behavior.max_ttl
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses

    content {
      error_code            = custom_error_response.value.error_code
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
    }
  }

  tags = var.tags
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = var.comment
}

data "aws_iam_policy_document" "this" {
  version = "2012-10-17"

  statement {
    sid = 1

    actions = [
      "cloudfront:CreateInvalidation",
    ]

    resources = [
      aws_cloudfront_distribution.this.arn
    ]
  }
}

