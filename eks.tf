


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}



#
# EKS
#
module "eks" {
  source = "./modules/eks"

  tags       = local.tags

  cluster_name = local.environment_name

  vpc_id         = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets
  

  cluster_version = "1.26"

  # public cluster - kubernetes API is publicly accessible
  cluster_endpoint_public_access = true


  # private cluster - kubernetes API is internal the the VPC
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    ng1 = {
      #create_launch_template = false
      launch_template_name   = "production-eks"

      # Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
      # (Optional) Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
      #force_update_version = true

      # doc: https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami
      # doc: https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami-bottlerocket.html
      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"
      version  = "1.26"

      disk_size      = 20
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.small"]
      additional_tags  = {
        Name = "production",
      }
      k8s_labels       = {}
    }
  }


cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }


  manage_aws_auth_configmap = true

}






module "vpc_cni_irsa" {
  source  = "./modules/iam/modules/iam-role-for-service-accounts-eks"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv6   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}



