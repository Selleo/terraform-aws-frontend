module "example_aws_frontend_app" {
  source = "./../../modules/aws-frontend-app"

  comment         = "My new website"
  aliases         = [var.app_domain_name]
  certificate_arn = aws_acm_certificate.my_app.arn

  s3_origin = {
    bucket_regional_domain_name = aws_s3_bucket.my_app.bucket_regional_domain_name
    path                        = "/my-app"
  }

  tags = {
    group = "Frontend"
    name  = "My app"
  }
}

# Route53 record

resource "aws_route53_record" "my_app" {
  zone_id = data.aws_route53_zone.my_app.zone_id
  name    = "test"
  type    = "A"

  alias {
    name                   = module.example_aws_frontend_app.domain_name
    zone_id                = module.example_aws_frontend_app.hosted_zone_id
    evaluate_target_health = true
  }
}

# s3

resource "aws_s3_bucket" "my_app" {
  bucket = var.app_s3_bucket_name
  acl    = "private"

  tags = {
    group = "Frontend"
    name  = "My app"
  }
}

data "aws_iam_policy_document" "s3_my_app" {
  version = "2012-10-17"

  statement {
    sid = 1

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.my_app.arn}/my-app/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [module.example_aws_frontend_app.oai_iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "my_app" {
  bucket = aws_s3_bucket.my_app.id

  policy = data.aws_iam_policy_document.s3_my_app.json
}

# cert

resource "aws_acm_certificate" "my_app" {
  provider = aws.global

  validation_method = "DNS"
  domain_name       = var.app_domain_name

  tags = {
    group = "Frontend"
    name  = "My app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# domain

resource "aws_route53_record" "cert_validation" {
  provider = aws.global

  for_each = {
    for dvo in aws_acm_certificate.my_app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.my_app.zone_id
  ttl     = 60
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
}

# alternatively you can use: https://github.com/terraform-aws-modules/terraform-aws-acm

data "aws_route53_zone" "my_app" {
  name         = var.route_53_zone_name
  private_zone = false
}

# deploy user

resource "aws_iam_user" "deployer" {
  name = "deployer"
}

# deployer policy for syncing with s3

data "aws_iam_policy_document" "deployer_s3_access" {
  version = "2012-10-17"

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.my_app.arn
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.my_app.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "deployer_s3_access" {
  name        = "deployer_s3_access"
  description = "Allows to sync files with s3"
  policy      = data.aws_iam_policy_document.deployer_s3_access.json
}

resource "aws_iam_user_policy_attachment" "deployer_s3_access" {
  user       = aws_iam_user.deployer.name
  policy_arn = aws_iam_policy.deployer_s3_access.arn
}

# deployer policy for cloudfront invalidation

resource "aws_iam_policy" "deployer_cdn_invalidation" {
  name        = "deployer_cdn_invalidation"
  description = "Allows to invalidate Cloudfront distribution"
  policy      = module.example_aws_frontend_app.distribution_invalidation_policy_json
}

resource "aws_iam_user_policy_attachment" "deployer_cdn_invalidation" {
  user       = aws_iam_user.deployer.name
  policy_arn = aws_iam_policy.deployer_cdn_invalidation.arn
}
