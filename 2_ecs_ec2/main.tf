locals {
  aws_region = "us-east-1"
  prefix     = "Terraform-ECS-Demo"
  common_tags = {
    Project   = local.prefix
    ManagedBy = "Terraform"
  }
  remote_state_bucket = "ecs-terraform-remote-state-s3"
  vpc_state_file      = "vpc.tfstate"
  service_port        = 80
  ssh_port            = 20
  task_def_name       = "nginx"
  aws_account_id      = 585584209241
  service_name = "nginx"
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

# ----- ECR repo ---------- #
resource "aws_ecr_repository" "nginx" {
  name                 = "nginx"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ----- security group for EC2 instnces ------#
module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "ec2_sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = local.service_port
      to_port     = local.service_port
      protocol    = "tcp"
      description = "http port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = local.ssh_port
      to_port     = local.ssh_port
      protocol    = "tcp"
      description = "ssh port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
    cidr_blocks = "0.0.0.0/0" }
  ]
}

# ------ Instance Profile EC2 ------#
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}


resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

# ------ ECS optimized AMI ------#

data "aws_ami" "aws_optimized_ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"] # AWS
}

# ------ aws key pair for ec2 ------#

resource "aws_key_pair" "ecs" {
  key_name   = "ecs"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDgvVaLYNGbQ7I+70EjjWJDGWXmQZ+gMT7BVaY+FSXZrOEnX2CPWfGcocOzRry13nWXtypJdUex0ix1pMgbhGUIXvLYVKnNhXJu6/CMNYLCL+SW8xY4yA2r7P/xzusDw6dKuyBlbp5uyWl8OiGaAGdGhUo6ROowx0gX+HnudUeZqUvhKCLfgoqV1kGfS8E5kYOtg0LVGgEEmDZtYnhqEgvdiU6nW2mb4HuUtdkONepazp3L6DWnASq2Tdz/gGISlJd9K2E9XdjdfD3E+gRgzIH69h1VUUxcJrMgephWke8A2MG2BcgjvxlS1GcFKDzUfZJM4WcegFlbJL8eDa/4d6ofEJGHbnUyS2LGw+u0pOl/gKcZUvwYH0ioGuDQA6HFVsGYBJBHFM2pAAJ8Xy50AlJGtVo+c/qbAMHWkWvhfe+5U/IIkNafFMLlS/k0w48BFmvVBgby6kXH25NP9LTivxwlKX95axcIxAsh8iwaPcWOmE4jMBIqXD1pIF/z2S5IZU= swezinlinn@Swes-MacBook-Pro.local"
}

# ------ launch configuration -------#

resource "aws_launch_configuration" "ecs_config_launch_config_spot" {
  name_prefix                 = "${var.cluster_name}_ecs_cluster_spot"
  image_id                    = data.aws_ami.aws_optimized_ecs.id
  instance_type               = var.instance_type_spot
  spot_price                  = var.spot_bid_price
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
  }
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
EOF

  security_groups = [module.ec2_sg.security_group_id]

  key_name             = aws_key_pair.ecs.key_name
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.arn
}

# -------- autoscale group --------#

resource "aws_autoscaling_group" "ecs_cluster_spot" {
  name_prefix = "${var.cluster_name}_asg_spot_"
  termination_policies = [
    "OldestInstance"
  ]
  default_cooldown          = 30
  health_check_grace_period = 30
  max_size                  = var.max_spot
  min_size                  = var.min_spot
  desired_capacity          = var.min_spot

  launch_configuration = aws_launch_configuration.ecs_config_launch_config_spot.name

  lifecycle {
    create_before_destroy = true
  }
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.public_subnets

  tags = [
    {
      key   = "Name"
      value = var.cluster_name,

      propagate_at_launch = true
    }
  ]
}

# -------- ecs cluster ---------#

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}

# --------- task definition -------#

resource "aws_ecs_task_definition" "task_definition" {
  family             = local.task_def_name
  execution_role_arn = "arn:aws:iam::${local.aws_account_id}:role/ecsTaskExecutionRole"
  memory             = 1024
  cpu                = 512
  container_definitions = jsonencode([
    {
      name      = local.task_def_name
      image     = "${local.aws_account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${local.task_def_name}:latest"
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
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

# ----- ecs service ----- #

resource "aws_ecs_service" "nginx" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 2
}
