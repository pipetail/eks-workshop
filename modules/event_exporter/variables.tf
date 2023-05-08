variable "name" {
  type        = string
  default     = "event-exporter"
  description = "Helm release name"
}

variable "namespace" {
  type        = string
  default     = "event-exporter"
  description = "kubernetes namespace to deploy to"
}

variable "atomic" {
  type        = bool
  default     = true
  description = "If set, installation process purges chart on fail. The wait flag will be set automatically if atomic is used."
}

variable "wait" {
  type        = bool
  default     = true
  description = "Will wait until all resources are in a ready state before marking the release as successful. It will wait for as long as timeout."
}

variable "chart_version" {
  type        = string
  default     = "2.3.2"
  description = "Helm chart version as per https://artifacthub.io/packages/helm/bitnami/kubernetes-event-exporter"
}



