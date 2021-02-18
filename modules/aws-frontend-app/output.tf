output "distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "CDN distribution ID."
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.this.arn
  description = "CDN distribution ARN."
}

output "domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CDN distribution's domain name."
}

output "hosted_zone_id" {
  value       = aws_cloudfront_distribution.this.hosted_zone_id
  description = "CDN Route 53 zone ID."
}

output "oai_iam_arn" {
  value       = aws_cloudfront_origin_access_identity.this.iam_arn
  description = "Origin Access Identity pre-generated ARN that can be used in S3 bucket policies."
}

output "distribution_invalidation_policy_json" {
  value       = data.aws_iam_policy_document.this.json
  description = "IAM policy document for invalidating CloudFront distribution."
}
