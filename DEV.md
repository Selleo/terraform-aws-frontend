# Development configuration

## Updating ingore files

Make sure `.gitignore` and `.terraformignore` files contain necessary rules.

## Generate module documentation

Install deps:
```
go get github.com/terraform-docs/terraform-docs
```

Generate documentation:
```
mkdir -p tmp/

terraform-docs markdown modules/aws-frontend-app/ > tmp/aws-frontend-app
```

then copy the output to appropriate README(s).

## Releasing

Make sure to update changelog.
