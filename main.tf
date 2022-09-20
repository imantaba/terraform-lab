terraform {
  required_version = ">= 0.12.0"
  backend "s3" {
    bucket         = "avid-tfbackend"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "avid-tfbackend"
  }
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
# Outputs can be retrieved at any time by running `terraform output`
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


provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "production.k8s.local"
}

resource "kubernetes_namespace" "terraform-first-namespace" {
  metadata {
    name = "tf-ns"
  }
}


# resource "kubernetes_deployment_v1" "example" {
#   metadata {
#     name = "tf-deployment-v1"
#     namespace = "tf-ns"
#     labels = {
#       app = "nginx"
#     }
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = "nginx"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "nginx"
#         }
#       }

#       spec {
#         container {
#           image = "nginx:latest"
#           name  = "webserver"

#           resources {
#             limits = {
#               cpu    = "0.5"
#               memory = "512Mi"
#             }
#             requests = {
#               cpu    = "250m"
#               memory = "50Mi"
#             }
#           }

#           liveness_probe {
#             http_get {
#               path = "/"
#               port = 80

#               http_header {
#                 name  = "X-Custom-Header"
#                 value = "Awesome"
#               }
#             }

#             initial_delay_seconds = 3
#             period_seconds        = 3
#           }
#         }
#       }
#     }
#   }
# }