output "vpc_id" {
  value       = module.ecs_vpc.vpc_id
  description = "VPC ID"
}

output "public_subnets" {
  value       = module.ecs_vpc.public_subnets
  description = "VPC public subnets' IDs list"
}

output "private_subnets" {
  value       = module.ecs_vpc.private_subnets
  description = "VPC private subnets' IDs list"
}
