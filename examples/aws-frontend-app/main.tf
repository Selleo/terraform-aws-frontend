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
    Group = "Frontend"
    Name  = "My app"
  }
}

# s3

resource "aws_s3_bucket" "my_app" {
  bucket = var.app_s3_bucket_name
  acl    = "private"

  tags = {
    Group = "Frontend"
    Name  = "My app"
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
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "my_app" {
  bucket = aws_s3_bucket.my_app.id

  policy = data.aws_iam_policy_document.s3_my_app.json
}

# cert

resource "aws_acm_certificate" "my_app" {
  validation_method = "DNS"
  domain_name       = var.app_domain_name

  tags = {
    Group = "Frontend"
    Name  = "My app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# domain

resource "aws_route53_record" "cert_validation" {
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

data "aws_route53_zone" "my_app" {
  name         = var.route_53_zone_name
  private_zone = false
}
