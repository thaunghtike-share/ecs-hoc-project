terraform {
  backend "s3" {
    bucket         = "ecs-terraform-remote-state-s3"
    key            = "vpc.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "ecs-terraform-remote-state-dynamodb"
  }
}
