provider "aws" {
    region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "XYZ-terraform-state-bucket"
    key    = "vpc-main.tfstate"
    region = "eu-west-1"
  }
}
