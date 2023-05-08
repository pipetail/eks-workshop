variable "name" {
  type        = string
  default     = "nginx-ingress"
  description = "Helm release name"
}

variable "namespace" {
  type        = string
  default     = "nginx-ingress"
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
  default     = "4.6.1"
  description = "Helm chart version"
}

variable "replica_count" {
  type        = number
  default     = 3
  description = "Controller replica count"
}

variable "memory_request" {
  type        = string
  default     = "1024Mi"
  description = "kubernetes deployment memory request"
}

variable "memory_limit" {
  type        = string
  default     = "1024Mi"
  description = "kubernetes deployment memory limit"
}

variable "cpu_request" {
  type        = string
  default     = "300m"
  description = "kubernetes deployment cpu request"
}

variable "cpu_limit" {
  type        = string
  default     = "300m"
  description = "kubernetes deployment cpu limit"
}

variable "http_nodeport" {
  description = "kubernetes service nodeport to expose HTTP"
  type        = number
  default     = 30080
}

variable "https_nodeport" {
  description = "kubernetes service nodeport to expose HTTPS"
  type        = number
  default     = 30443
}
