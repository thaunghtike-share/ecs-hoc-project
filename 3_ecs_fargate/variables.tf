variable "cluster_name" {
  default     = "ecs_terraform_fargate"
  type        = string
  description = "the name of ECS cluster"
}

variable "wp_db_name" {
  default = "wordpress"
}

variable "wp_db_user" {
  default = "wordpress"
}

variable "wp_db_password" {
  default = "wordpress"
}

variable "wp_db_host" {
  default = "url"
}

variable "alb_name" {
  default = "wordpress-alb"
}
