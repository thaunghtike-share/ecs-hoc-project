## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alb\_name | n/a | `string` | `"wordpress-alb"` | no |
| cluster\_name | the name of ECS cluster | `string` | `"ecs_terraform_fargate"` | no |
| wp\_db\_host | n/a | `string` | `"url"` | no |
| wp\_db\_name | n/a | `string` | `"wordpress"` | no |
| wp\_db\_password | n/a | `string` | `"wordpress"` | no |
| wp\_db\_user | n/a | `string` | `"wordpress"` | no |

## Outputs

No output.
