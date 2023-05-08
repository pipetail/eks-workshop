data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  cluster_oidc_issuer = replace(var.cluster_oidc_issuer_url, "https://", "")
}

resource "aws_iam_role" "this" {
  name = "${var.name_prefix}eks-cluster-autoscaler"

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
            "${local.cluster_oidc_issuer}:sub" = "system:serviceaccount:${var.namespace}:${var.name}-aws-cluster-autoscaler"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "this" {
  name = "${var.name_prefix}eks-cluster-autoscaling"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = [
          "*",
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = [
          "*",
        ]
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = var.chart_version
  atomic           = var.atomic
  wait             = var.wait
  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      cluster_name = var.cluster_name,
      region       = data.aws_region.current.name,
      role_arn     = aws_iam_role.this.arn,
    })
  ]
}
