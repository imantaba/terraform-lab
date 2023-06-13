variable "namespace_name" {
  default = "cattle-system"
}

variable "create_namespace" {
  type        = bool
  description = "(Optional) Create namespace?"
  default     = true
}

variable "chart_version" {
  type        = string
  description = "HELM Chart Version for cert-manager"
  default     = "2.7.0"
}

variable "additional_set" {
  description = "Additional sets to Helm"
  default     = []
}

variable "hostname" {
  type        = string
  description = "Hostname of the rancher"
  default     = "rancher.local"
}

variable "tls_source" {
  type        = string
  description = "Tls Source of the rancher"
  default     = "letsEncrypt"
}

variable "letsEncrypt_email" {
  type        = string
  description = "LetsEncrypt email used for the rancher"
  default     = "letsencrypt@avidcloud.io"
}
