
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

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

data "aws_caller_identity" "current" {}



#
# EKS
#
module "eks" {
  source = "./modules/eks"

  tags = local.tags

  cluster_name = local.environment_name

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = [module.vpc.private_subnets[0]]
  control_plane_subnet_ids = module.vpc.intra_subnets


  cluster_version = local.cluster_version

  # public cluster - kubernetes API is publicly accessible
  cluster_endpoint_public_access = true


  # private cluster - kubernetes API is internal the the VPC
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    production_eks = {
      launch_template_name = "production-eks-bottlerocket"

      # Current bottlerocket AMI
      # ami_id   = data.aws_ami.eks_default_bottlerocket.image_id
      ami_id   = "ami-0838f541fae49f440"
      platform = "bottlerocket"

      # Use module user data template to bootstrap
      enable_bootstrap_user_data = true


      max_size     = 12
      min_size     = 3
      desired_size = 4

      # Ignoring Changes to Desired Size

      # WE utilized the generic Terraform resource lifecycle configuration block with ignore_changes to create an EKS 
      # Node Group with an initial size of running instances, then ignore any changes to that count caused externally (e.g., Application Autoscaling).
      #   lifecycle {
      #     ignore_changes = [scaling_config[0].desired_size]
      #   }


      instance_types = ["t3a.2xlarge", "r5a.xlarge"]
      # Use module user data template to bootstrap
      enable_bootstrap_user_data = true
      # This will get added to the template
      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false
        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true
      EOT

      block_device_mappings = [
        {
          device_name = "/dev/xvda"

          ebs = {
            volume_size           = "20"
            volume_type           = "gp3"
            delete_on_termination = "true"
          }
        },
        {
          device_name = "/dev/xvdb"

          ebs = {
            volume_size           = "100"
            volume_type           = "gp3"
            delete_on_termination = "true"
          }
        }
      ]


      create_iam_role          = true
      iam_role_name            = "eks-production-node-group"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS production managed node group role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        additional                         = aws_iam_policy.node_additional.arn
        SSMpolicy                          = aws_iam_policy.node_ssm.arn
      }
      additional_tags = {
        Name = "production",
      }
      k8s_labels = {
        IsPrimary = "true"
      }
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
    aws-ebs-csi-driver = {
      addon_version            = "v1.18.0-eksbuild.1"
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }


}


module "vpc_cni_irsa" {
  source = "./modules/iam/modules/iam-role-for-service-accounts-eks"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}


module "ebs_csi_driver_irsa" {
  source = "./modules/iam/modules/iam-role-for-service-accounts-eks"

  role_name_prefix      = "EBS-CSI-DRIVER-IRSA"
  attach_vpc_cni_policy = true
  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}



data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${local.cluster_version}-x86_64-*"]
  }
}

resource "aws_iam_policy" "node_additional" {
  name        = "eks-production-additional"
  description = "eks production cluster nodes additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}


resource "aws_iam_policy" "node_ssm" {
  name        = "eks-production-ssm"
  description = "eks production cluster nodes SSM policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:PutMetricData"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstanceStatus"
        ],
        "Resource" : "*"
      }
    ]
  })

  tags = local.tags
}


### StorageClass
resource "kubernetes_storage_class" "gp3-topologyaware-expandable-csi" {
  metadata {
    name = "gp3-topologyaware-expandable-csi"
  }
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = "true"

  depends_on = [module.ebs_csi_driver_irsa.iam_role_arn]
}
