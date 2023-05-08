locals {
  nginx_ingress_ports = {
    http  = 30080
    https = 30443
  }
}

# as per https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html
resource "kubernetes_storage_class" "ebs_sc" {
  metadata {
    name = "ebs-sc"
  }
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

resource "kubernetes_cluster_role" "readonly" {
  metadata {
    name = "viewonly"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "persistentvolumeclaims", "pods", "replicationcontrollers", "replicationcontrollers/scale", "serviceaccounts", "services", "nodes", "persistentvolumeclaims", "persistentvolumes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["bindings", "events", "limitranges", "namespaces/status", "pods/log", "pods/status", "replicationcontrollers/status", "resourcequotas", "resourcequotas/status"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["daemonsets", "deployments", "deployments/scale", "replicasets", "replicasets/scale", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "deployments/scale", "ingresses", "networkpolicies", "replicasets", "replicasets/scale", "replicationcontrollers/scale"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "volumeattachments"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterrolebindings", "clusterroles", "roles", "rolebindings"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "readonly" {
  metadata {
    name = "kubernetes-dashboard"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "viewonly"
  }
  subject {
    kind      = "Group"
    name      = "viewonly"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  metadata {
    name = "cluster-autoscaler"
  }
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

resource "kubernetes_namespace" "event_exporter" {
  metadata {
    name = "event-exporter"
  }
}

resource "kubernetes_namespace" "app_1" {
  metadata {
    name = "app1"
  }
}

resource "kubernetes_namespace" "app_2" {
  metadata {
    name = "app2"
  }
}

resource "kubernetes_namespace" "app_3" {
  metadata {
    name = "app3"
  }
}

module "nginx_ingress" {
  source        = "../modules/nginx_ingress"
  namespace     = kubernetes_namespace.nginx_ingress.metadata[0].name
  name          = "nginx-ingress"
  replica_count = 1

  http_nodeport  = local.nginx_ingress_ports.http
  https_nodeport = local.nginx_ingress_ports.https
}

module "cluster_autoscaler" {
  source = "../modules/cluster_autoscaler"

  name      = "cluster-autoscaler"
  namespace = kubernetes_namespace.cluster_autoscaler.metadata[0].name

  cluster_name            = module.eks.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
}

module "fluent_bit" {
  source = "../modules/fluent_bit"

  namespace = kubernetes_namespace.logging.metadata[0].name

  cluster_name            = module.eks.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
}

module "event_exporter" {
  source = "../modules/event_exporter"

  namespace = kubernetes_namespace.event_exporter.metadata[0].name
}