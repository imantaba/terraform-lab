
module "cert_manager" {
  source        = "./modules/cert-manager"

  cluster_issuer_email                   = "letsencrypt@avidcloud.io"
  cluster_issuer_name                    = "letsencrypt"
  cluster_issuer_private_key_secret_name = "letsencrypt-issuer-account-key"
  chart_version                          = "1.11.2"
  additional_set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "cert-manager"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.cert_manager_irsa_role.iam_role_arn
    }
  ]
  solvers                                = [{
    dns01 = {
      route53 = {
        region  = "eu-central-1"
        # role = module.cert_manager_irsa_role.iam_role_arn
      }
    }
  }]
}


module "cert_manager_irsa_role" {
  source = "./modules/iam/modules/iam-role-for-service-accounts-eks"

  role_name      = "CERT-MANAGER-IRSA"
  # attach_cert_manager_policy    = true
  # cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/*"]
  role_policy_arns = {
    policy = aws_iam_policy.cert_manager_policy.arn
  }
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }

  tags = local.tags
}


resource "aws_iam_policy" "cert_manager_policy" {
  name        = "cert-manager-policy"
  path        = "/"
  description = "Policy, which allows CertManager to create Route53 records"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
            "Action": [
                "route53:GetChange",
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "route53:ListHostedZonesByName"
            ],
      "Resource": "*"
    }
  ]
})
}