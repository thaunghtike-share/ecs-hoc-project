locals {
  aws_region = "us-east-1"
  prefix     = "Terraform-ECS-Demo"
  common_tags = {
    Project   = local.prefix
    ManagedBy = "Terraform"
  }
  vpc_cidr = var.vpc_cidr
}

module "ecs_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.prefix}-vpc"
  cidr = local.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway               = true
  enable_dns_hostnames = true


  tags = local.common_tags
}
