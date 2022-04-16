## Deployment
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

## Tier Down

```bash
terraform destroy -auto-approve
```

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

No input.

## Outputs

| Name | Description |
|------|-------------|
| dynamodb-lock-table | DynamoDB table for Terraform execution locks |
| dynamodb-lock-table-ssm-parameter | SSM parameter containing DynamoDB table for Terraform execution locks |
| s3-state-bucket | S3 bucket for storing Terraform state |
| s3-state-bucket-ssm-parameter | SSM parameter containing S3 bucket for storing Terraform state |

