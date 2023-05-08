data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  cluster_oidc_issuer = replace(var.cluster_oidc_issuer_url, "https://", "")
  data = {
    "application-log.conf" = "${file("${path.module}/application-log.conf")}"
    "dataplane-log.conf"   = "${file("${path.module}/dataplane-log.conf")}"
    "fluent-bit.conf"      = "${file("${path.module}/fluent-bit.conf")}"
    "host-log.conf"        = "${file("${path.module}/host-log.conf")}"
    "parsers.conf"         = "${file("${path.module}/parsers.conf")}"
  }
}

resource "aws_iam_role" "this" {
  name = "${var.name_prefix}eks-fluent-bit"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.cluster_oidc_issuer}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {

          StringLike = {
            "${local.cluster_oidc_issuer}:sub" = "system:serviceaccount:${var.namespace}:fluent-bit"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  name = "${var.name_prefix}eks-fluent-bit"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
        ]
        Resource = [
          "*",
        ]
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = "fluent-bit"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
  }
}

resource "kubernetes_cluster_role" "this" {
  metadata {
    name = "fluent-bit"
  }

  rule {
    non_resource_urls = [
      "/metrics"
    ]
    verbs = [
      "get"
    ]
  }

  rule {
    api_groups = [""]
    resources = [
      "namespaces",
      "pods",
      "pods/logs",
      "nodes",
      "nodes/proxy",
    ]
    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
}

resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name = "fluent-bit"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.this.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_config_map" "this" {
  metadata {
    name      = "fluent-bit-config"
    namespace = var.namespace
  }

  data = local.data
}

resource "kubernetes_daemonset" "this" {
  metadata {
    name      = "fluent-bit"
    namespace = var.namespace
    labels = {
      "k8s-app"                       = "fluent-bit"
      "version"                       = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }

  spec {
    selector {
      match_labels = {
        "k8s-app" = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app"                       = "fluent-bit"
          "version"                       = "v1"
          "kubernetes.io/cluster-service" = "true"
        }

        annotations = {
          "config/hash" = md5(jsonencode(local.data))
        }
      }

      spec {
        volume {
          name = "fluentbitstate"
          host_path {
            path = "/var/fluent-bit/state"
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.this.metadata[0].name
          }
        }

        volume {
          name = "runlogjournal"
          host_path {
            path = "/run/log/journal"
          }
        }

        volume {
          name = "dmesg"
          host_path {
            path = "/var/log/dmesg"
          }
        }

        service_account_name = kubernetes_service_account.this.metadata[0].name

        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        toleration {
          operator = "Exists"
          effect   = "NoExecute"
        }

        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
          name  = "fluent-bit"

          resources {
            limits = {
              memory = "200Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "200Mi"
            }
          }

          env {
            name  = "AWS_REGION"
            value = data.aws_region.current.name
          }

          env {
            name  = "CLUSTER_NAME"
            value = var.cluster_name
          }

          env {
            name  = "HTTP_SERVER"
            value = "On"
          }

          env {
            name  = "HTTP_PORT"
            value = "2020"
          }

          env {
            name  = "READ_FROM_HEAD"
            value = "Off"
          }

          env {
            name  = "READ_FROM_TAIL"
            value = "On"
          }

          env {
            name = "HOST_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.name"
              }
            }
          }

          env {
            name  = "CI_VERSION"
            value = "k8s/1.3.14"
          }

          volume_mount {
            name       = "fluentbitstate"
            mount_path = "/var/fluent-bit/state"
          }

          volume_mount {
            name       = "varlog"
            read_only  = true
            mount_path = "/var/log"
          }

          volume_mount {
            name       = "varlibdockercontainers"
            read_only  = true
            mount_path = "/var/lib/docker/containers"
          }

          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc/"
          }

          volume_mount {
            name       = "runlogjournal"
            read_only  = true
            mount_path = "/run/log/journal"
          }

          volume_mount {
            name       = "dmesg"
            read_only  = true
            mount_path = "/var/log/dmesg"
          }
        }
      }
    }
  }
}