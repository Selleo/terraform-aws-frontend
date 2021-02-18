output "distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "CDN distribution ID."
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
  description = "OAI pre-generated ARN that can be used in S3 bucket policies"
}
