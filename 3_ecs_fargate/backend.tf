terraform {
  backend "s3" {
    bucket  = "ecs-terraform-remote-state-s3"
    key     = "ecs-on-fargate.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }
}
