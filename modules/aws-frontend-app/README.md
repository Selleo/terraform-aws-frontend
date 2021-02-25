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


