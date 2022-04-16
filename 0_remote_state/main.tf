locals {
    aws_region  = "us-east-1"
    prefix      = "tho-terraform-remote-state"
    ssm_prefix  = "/terraform/lab"
    common_tags = {
        Project         = "ECS_Terraform"
        ManagedBy       = "Terraform"
    }
}