module "efs_csi_driver" {
  source = "./modules/efs-csi-driver"

  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  helm_chart_version = "2.4.3"
}