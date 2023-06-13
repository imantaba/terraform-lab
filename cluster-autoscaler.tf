
module "cluster_autoscaler" {
  source        = "./modules/cluster-autoscaler"
  namespace_name = "kube-system"
  create_namespace = false

  chart_version                          = "9.28.0"

  # find chart values from below code
  # https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler#aws---using-auto-discovery-of-tagged-instance-groups
  
  additional_set = [
    {
      name  = "autoDiscovery.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "awsRegion"
      value = local.aws_region
    },
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.cluster_autoscaler_irsa_role.iam_role_arn
    }
  ]
}


module "cluster_autoscaler_irsa_role" {
  source = "./modules/iam/modules/iam-role-for-service-accounts-eks"

  role_name      = "CLUSTER-AUTOSCALER-IRSA"
  # attach_cluster_autoscaler_policy = true
  # cluster_autoscaler_cluster_ids   = [module.eks.cluster_id]
  role_policy_arns = {
    policy = aws_iam_policy.cluster_autoscaler_policy.arn
  }
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = local.tags
}


resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "AmazonEKS_Cluster_Autoscaler_Policy"
  path        = "/"
  description = "Policy, which allows Cluster_Autoscaler to Manage EC2 instances"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeImages",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    }
  ]
})
}