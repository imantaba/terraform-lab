terraform {
  required_version = ">= 0.12.0"
}


# provider "aws" {
#   region = "eu-central-1"
# }


# RESOURCES
# Objects managed by Terraform such as VPCs, S3 buckets, IAM users, etc.
# Declaring a Resource tells Terraform that it should CREATE
# and manage the Resource described. If the resource already exists
# it must be imported into Terraform's state.
resource "aws_s3_bucket" "bucket1" {
  bucket = "${data.aws_caller_identity.current.account_id}-imanbucket"
}

# Data Sources
# Objects NOT managed by Terraform . That are not resources that you can create
data "aws_caller_identity" "current" {
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Outputs
# Outputs are printed by the CLI after `apply`.
# this can reveal calculated values or other information
# Also used in more advanced use cases :  modules, remote_state
# Outputs can be retrieved at any time bu running `terraform output`
output "bucket_info" {
  value = aws_s3_bucket.bucket1
}

output "aws_caller_inf" {
  value = data.aws_caller_identity.current
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available
}


output "bucketname" {
  value = data.aws_caller_identity.current.account_id
}


# Dependency
# Resources can depend on one another. Terraform will ensure that all dependencies are met before creating the resource.
# Dependencies can be implicit or explicit.
resource "aws_s3_bucket" "bucket2" {
  bucket = "${data.aws_caller_identity.current.account_id}-bucket2"
  tags = {
    # Implicit dependency
    dependency = aws_s3_bucket.bucket1.arn
  }
}
  
resource "aws_s3_bucket" "bucket3" {
  bucket = "${data.aws_caller_identity.current.account_id}-bucket3"
  # Explicit dependency
  depends_on = [
    aws_s3_bucket.bucket2
  ]
}