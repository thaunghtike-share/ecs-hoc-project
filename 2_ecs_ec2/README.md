No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | the name of an ECS cluster | `string` | `"ecs_terraform_ec2"` | no |
| instance\_type\_spot | n/a | `string` | `"t3a.medium"` | no |
| max\_spot | The maximum EC2 spot instances that can be launched at peak time | `string` | `"5"` | no |
| min\_spot | The minimum EC2 spot instances to be available | `string` | `"2"` | no |
| spot\_bid\_price | How much you are willing to pay as an hourly rate for an EC2 instance, in USD | `string` | `"0.0175"` | no |

## Outputs

No output.

