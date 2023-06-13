resource "kubernetes_namespace" "cert_manager" {
  count = var.create_namespace ? 1 : 0

  metadata {
    annotations = {
      name = var.namespace_name
    }
    name = var.namespace_name
  }
}

resource "helm_release" "rancher" {
  chart      = "rancher"
  repository = "https://releases.rancher.com/server-charts/stable"
  name       = "rancher"
  namespace  = var.create_namespace ? kubernetes_namespace.cert_manager[0].id : var.namespace_name
  version    = var.chart_version

  create_namespace = false

  set {
    name  = "hostname"
    value = var.hostname
  }
  set {
    name  = "ingress.tls.source"
    value = var.tls_source
  }
  set {
    name  = "letsEncrypt.email"
    value = var.letsEncrypt_email
  }
  dynamic "set" {
    for_each = var.additional_set
    content {
      name  = set.value.name
      value = set.value.value
      type  = lookup(set.value, "type", null)
    }
  }
}