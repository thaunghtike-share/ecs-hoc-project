## Requirements

| Name | Version |
|------|---------|
| aws | ~> 3.0 |

## Providers

No provider.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azs | the name of availability zones to use subnets | `list(string)` | <pre>[<br>  "us-east-1a",<br>  "us-east-1b"<br>]</pre> | no |
| private\_subnets | the CIDR blocks to create private subnets | `list(string)` | <pre>[<br>  "10.100.30.0/24",<br>  "10.100.40.0/24"<br>]</pre> | no |
| public\_subnets | the CIDR blocks to create public subnets | `list(string)` | <pre>[<br>  "10.100.10.0/24",<br>  "10.100.20.0/24"<br>]</pre> | no |
| vpc\_cidr | n/a | `string` | `"10.100.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| private\_subnets | VPC private subnets' IDs list |
| public\_subnets | VPC public subnets' IDs list |
| vpc\_id | VPC ID |

