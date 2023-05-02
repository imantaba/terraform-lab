locals {
  aws_region       = "eu-central-1"
  region           = "eu-central-1"
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  environment_name = "production"
  vpc_cidr         = "10.0.0.0/16"
  tags = {
    ops_env              = "${local.environment_name}"
    ops_managed_by       = "terraform",
    ops_owners           = "devops",
  }
}

data "aws_availability_zones" "available" {}
terraform {
  required_version = ">= 0.12.0"
  backend "s3" {
    bucket         = "avid-tfbackend"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "avid-tfbackend"
  }
 required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.59.0"
    }
  }
}


provider "aws" {
  region = "eu-central-1"
}


