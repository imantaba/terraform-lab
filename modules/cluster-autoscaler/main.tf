resource "kubernetes_namespace" "cluster_autoscaler" {
  count = var.create_namespace ? 1 : 0

  metadata {
    annotations = {
      name = var.namespace_name
    }
    name = var.namespace_name
  }
}

resource "helm_release" "cluster_autoscaler" {
  chart      = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  name       = "cluster-autoscaler"
  namespace  = var.create_namespace ? kubernetes_namespace.cluster_autoscaler[0].id : var.namespace_name
  version    = var.chart_version

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
