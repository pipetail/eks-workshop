variable "namespace" {
  type        = string
  description = "namespace where fluentbit is installed"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_oidc_issuer_url" {
  type        = string
  description = "EKS cluster oidc issuer url"
}

variable "name_prefix" {
  type        = string
  description = "name prefix for unique resource names"
  default     = ""
}

