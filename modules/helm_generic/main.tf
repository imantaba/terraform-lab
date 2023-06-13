resource "kubernetes_namespace" "cluster_autoscaler" {
  count = var.create_namespace ? 1 : 0

  metadata {
    annotations = {
      name = var.namespace_name
    }
    name = var.namespace_name
  }
}

resource "helm_release" "helm_chart" {
  chart      = var.chart
  repository = var.repository
  name       = var.name
  namespace  = var.create_namespace ? kubernetes_namespace.cluster_autoscaler[0].id : var.namespace_name
  version    = var.chart_version
   values     = [file(var.helm_values)]
  create_namespace = false


  dynamic "set" {
    for_each = var.additional_set
    content {
      name  = set.value.name
      value = set.value.value
      type  = lookup(set.value, "type", null)
    }
  }
}
