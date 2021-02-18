# AWS Frontend app example

In order to use this module you need to have following prerequisites:

- S3 bucket
- SSL Certificate 
- Domain name

## Usage

Define app using module without `aliases`. They will defined later as domain needs to be associated with Cloudfront distribution first.

```tf
module "example_aws_frontend_app" {
  source = "Selleo/frontend/aws//examples/aws-frontend-app"
  version = "0.0.3"

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
