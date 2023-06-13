variable "namespace_name" {
  default = "kube-system"
}

variable "create_namespace" {
  type        = bool
  description = "(Optional) Create namespace?"
  default     = false
}

variable "chart_version" {
  type        = string
  description = "HELM Chart Version for cluster_autoscaler"
  default     = "9.28.0"
}

variable "additional_set" {
  description = "Additional sets to Helm"
  default     = []
}
