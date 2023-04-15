locals {
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

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


