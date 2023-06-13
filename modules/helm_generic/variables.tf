variable "namespace_name" {
  default = "default"
}

variable "create_namespace" {
  type        = bool
  description = "(Optional) Create namespace?"
  default     = false
}

variable "chart" {
  type        = string
  description = "HELM Chart name"
  default     = "bitnami"
}

variable "name" {
  type        = string
  description = "HELM  name"
  default     = "bitnami"
}

variable "chart_version" {
  type        = string
  description = "HELM Chart Version for cluster_autoscaler"
  default     = "13.13.0"
}

variable "repository" {
  type        = string
  description = "HELM Chart repository"
  default     = "https://charts.bitnami.com/bitnami"
}

variable "additional_set" {
  description = "Additional sets to Helm"
  default     = []
}

variable "helm_values" {
  type        = string
  description = "HELM Chart Version for cluster_autoscaler"
  default     = ""
}