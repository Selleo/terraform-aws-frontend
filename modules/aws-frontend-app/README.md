# AWS Frontend App 

Terraform module which creates CloudFront distribution for frontend application.

In order to use this module you need to have following prerequisites:

- S3 bucket
- SSL Certificate 
- Domain name

## Usage

Define app using module without `aliases`. They will defined later as domain needs to be associated with Cloudfront distribution first.

```tf
module "example_aws_frontend_app" {
  source = "Selleo/frontend/aws//modules/aws-frontend-app"
  version = "0.0.7"

  comment         = "My new website"
  aliases         = []
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
```

Create association between module output `domain_name` and your domain. For Route53 create `A` record for this. When using other DNS provider use `CNAME`.
Once your domain is associated and DNS changes have propagated update your module aliases.

```tf
module "example_aws_frontend_app" {
  ...

  aliases = ["app.example.org"]

  ...
}
```

## How to deploy using AWS CLI

For complex app structure use `aws s3 sync` instead of `aws s3 copy`.

```bash
echo '<html><body><h1>Hello there!</h1></body></html>' > index.html^C
aws --profile AWS_PROFILE_NAME_HERE s3 cp index.html s3://BUCKET_NAME_HERE/my-app/
aws --profile AWS_PROFILE_NAME_HERE cloudfront create-invalidation --distribution-id DISTRO_ID_HERE --paths '/*'
```

## Using module with JS frameworks

When using module with JS frameworks (React, Ember, ...) beware of routing.

Consider the following example:

```
https://example.com/my-route
```

When accessing above URL directly CloudFront will attempt to match `my-route` path on S3 file structure which may cause to return 403/404 errors (depending on you S3 policies).
This happens because client-side applications typically don't have folder structure reflecting URL paths (like in Hugo/Jekyll) and rely on the internal handler to do the routing.
In order to resolve this issue you can force CDN to fallback to default root object that will handle the routing:


```hcl
module "example_aws_frontend_app" {
  ...

  custom_error_responses = [
    {
      error_code            = 403
      error_caching_min_ttl = 86400
      response_code         = 200
      response_page_path    = "/index.html"
    },
    {
      error_code            = 404
      error_caching_min_ttl = 86400
      response_code         = 200
      response_page_path    = "/index.html"
    },
  ]
```

This will cause CDN to go through `index.html` first for any matching error.

For hash based routers that's not the case since all paths are resolved to the root object:

```
https://example.com/#/my-route
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aliases"></a> [aliases](#input\_aliases) | List of CNAMEs | `list(string)` | n/a | yes |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | AWS ACM certificate ARN. | `string` | n/a | yes |
| <a name="input_certificate_minimum_protocol_version"></a> [certificate\_minimum\_protocol\_version](#input\_certificate\_minimum\_protocol\_version) | The minimum version of the SSL protocol that you want to use for HTTPS. | `string` | `"TLSv1.2_2019"` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Any comment you want to add to the distribution for easier identification. | `string` | n/a | yes |
| <a name="input_custom_error_responses"></a> [custom\_error\_responses](#input\_custom\_error\_responses) | List of custom error responses for distribution. | <pre>list(object({<br>    error_code            = number<br>    error_caching_min_ttl = number<br>    response_code         = number<br>    response_page_path    = string<br>  }))</pre> | `[]` | no |
| <a name="input_default_cache_behavior"></a> [default\_cache\_behavior](#input\_default\_cache\_behavior) | Default cache behavior for this distribution | <pre>object({<br>    allowed_methods = list(string),<br>    cached_methods  = list(string),<br>    min_ttl         = number<br>    max_ttl         = number<br>    default_ttl     = number<br>    compress        = bool<br>  })</pre> | <pre>{<br>  "allowed_methods": [<br>    "DELETE",<br>    "GET",<br>    "HEAD",<br>    "OPTIONS",<br>    "PATCH",<br>    "POST",<br>    "PUT"<br>  ],<br>  "cached_methods": [<br>    "GET",<br>    "HEAD"<br>  ],<br>  "compress": true,<br>  "default_ttl": 3600,<br>  "max_ttl": 86400,<br>  "min_ttl": 0<br>}</pre> | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | The object that you want CDN to return when an user requests the root URL. | `string` | `"index.html"` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Cloudfront distribution's price class. | `string` | `"PriceClass_100"` | no |
| <a name="input_s3_origin"></a> [s3\_origin](#input\_s3\_origin) | S3 origin configuration | <pre>object({<br>    path                        = string<br>    bucket_regional_domain_name = string<br>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags attached to Cloudfront distribution. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_distribution_arn"></a> [distribution\_arn](#output\_distribution\_arn) | CDN distribution ARN. |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | CDN distribution ID. |
| <a name="output_distribution_invalidation_policy_json"></a> [distribution\_invalidation\_policy\_json](#output\_distribution\_invalidation\_policy\_json) | IAM policy document for invalidating CloudFront distribution. |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | CDN distribution's domain name. |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | CDN Route 53 zone ID. |
| <a name="output_oai_iam_arn"></a> [oai\_iam\_arn](#output\_oai\_iam\_arn) | Origin Access Identity pre-generated ARN that can be used in S3 bucket policies. |
