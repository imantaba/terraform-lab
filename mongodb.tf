module "bitnami_mongodb" {
  source = "./modules/helm_generic"

  name = "mongodb-production"
  namespace_name = "mongodb-production"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart = "mongodb"
  chart_version = "13.13.0"
  helm_values = "./helm_values/mongodb-values.yml"
}