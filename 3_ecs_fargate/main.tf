locals {
  aws_region = "us-east-1"
  prefix     = "Terraform-ECS-Demo"
  common_tags = {
    Project   = local.prefix
    ManagedBy = "Terraform"
  }
  remote_state_bucket = "ecs-terraform-remote-state-s3"
  vpc_state_file      = "vpc.tfstate"
  task_def_name       = "wordpress"
  image_name          = "wordpress"
  service_name        = "wordpress"
  service_port        = 80
  aws_account_id      = 585584209241
  alb_name            = var.alb_name
  target_group_name   = "ecs"
  ecs_service_sg_name = "ecs_task_sg"

}

# -------- vpc remote state -------#
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = local.remote_state_bucket
    region = local.aws_region
    key    = local.vpc_state_file
  }
}

# ------- ecs task execution role -----#

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------ create ecs cluster -----#
resource "aws_ecs_cluster" "ecs_fargate" {
  name = var.cluster_name
}

# ------ create task definition -----#

resource "aws_ecs_task_definition" "wordpress" {
  family                   = local.task_def_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = "arn:aws:iam::${local.aws_account_id}:role/ecsTaskExecutionRole"
  memory                   = 4096
  cpu                      = 2048
  container_definitions = jsonencode([
    {
      name      = "${local.image_name}"
      image     = "${local.image_name}:latest"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = local.service_port
          hostPort      = local.service_port
        }
      ]
      environment = [
        {
          "name" : "WORDPRESS_DB_USER",
          "value" : var.wp_db_user
        },
        {
          "name" : "WORDPRESS_DB_HOST",
          "value" : var.wp_db_host
        },
        {
          "name" : "WORDPRESS_DB_PASSWORD",
          "value" : var.wp_db_password
        },
        {
          "name" : "WORDPRESS_DB_NAME",
          "value" : var.wp_db_name
        }
      ]
    }
  ])
  tags = merge(
    local.common_tags,
    {
      Name = local.task_def_name
    }
  )
}

# ---- create a security group for ALB ----#

resource "aws_security_group" "alb_sg" {
  name   = local.alb_name
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port        = local.service_port
    to_port          = local.service_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.alb_name
  }
}

# ----- create an ALb -----#

resource "aws_lb" "ecs_alb" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnets

  enable_deletion_protection = false
}

resource "aws_alb_target_group" "ecs_alb_target_group" {
  name        = local.target_group_name
  port        = local.service_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.id
  port              = local.service_port
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.ecs_alb_target_group.arn
    type             = "forward"
  }
}

# ----- create a security group for ecs task -----#

resource "aws_security_group" "ecs_task_sg" {
  name   = local.ecs_service_sg_name
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups = ["${aws_security_group.alb_sg.id}"] 
  } 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = local.ecs_service_sg_name
  }
}

# ----- create an ECS service ------#

resource "aws_ecs_service" "wordpress" {
  name                               = local.service_name
  cluster                            = aws_ecs_cluster.ecs_fargate.id
  task_definition                    = aws_ecs_task_definition.wordpress.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  platform_version                   = "1.4.0"
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_task_sg.id}"]
    subnets          = data.terraform_remote_state.vpc.outputs.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_alb_target_group.arn
    container_name   = local.image_name
    container_port   = local.service_port
  }
}
