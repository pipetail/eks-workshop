resource "helm_release" "this" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  wait             = var.wait
  atomic           = var.atomic

  values = [
    templatefile("${path.module}/values.yaml", {
      replica_count  = var.replica_count,
      memory_request = var.memory_request,
      memory_limit   = var.memory_limit,
      cpu_request    = var.cpu_request,
      cpu_limit      = var.cpu_limit,
      http_nodeport  = var.http_nodeport,
      https_nodeport = var.https_nodeport,
    })
  ]
}
