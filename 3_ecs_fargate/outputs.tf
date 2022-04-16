output "alb_dns" {
  value       = aws_lb.ecs_alb.dns_name
  description = "the DNS name of the load balancer"

}
