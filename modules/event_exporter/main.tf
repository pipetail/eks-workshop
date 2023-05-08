resource "helm_release" "this" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = true
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "kubernetes-event-exporter"
  version          = var.chart_version
  wait             = var.wait
  atomic           = var.atomic

  values = [
    templatefile("${path.module}/values.yaml", {
    })
  ]
}
