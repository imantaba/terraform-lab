output "namespace" {
  value = var.create_namespace ? kubernetes_namespace.cert_manager[0].id : var.namespace_name
}
