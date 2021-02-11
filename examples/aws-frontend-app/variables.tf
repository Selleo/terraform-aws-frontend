variable "route_53_zone_name" {
  type        = string
  description = "Route 53 zone name."
}

variable "app_domain_name" {
  type        = string
  description = "Alias for the frontend application. In addition a certificate for it will be generated."
}

variable "app_s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for the application build."
}
