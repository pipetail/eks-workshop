resource "aws_iam_policy" "eks_kubeconfig" {
  name        = "eks_kubeconfig"
  path        = "/"
  description = "allow obtaining of kubeconfig for all EKS clusters"

  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = [
          "*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi"
        ]
        Resource = [
          "*",
        ]
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role" "eks_access_administrator" {
  name = "eks_workshop_${data.aws_region.current.name}_administrator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
          ]
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_access_administrator_kubeconfig" {
  policy_arn = aws_iam_policy.eks_kubeconfig.arn
  role       = aws_iam_role.eks_access_administrator.name
}

resource "aws_iam_user" "student" {
  name = "student"
}

resource "aws_iam_user_login_profile" "student" {
  user                    = aws_iam_user.student.name
  password_reset_required = false
}

output "student_password" {
  value     = aws_iam_user_login_profile.student.password
  sensitive = true
}

resource "aws_iam_user_policy_attachment" "student_view_only_access" {
  user       = aws_iam_user.student.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "student_kubeconfig" {
  user       = aws_iam_user.student.name
  policy_arn = aws_iam_policy.eks_kubeconfig.arn
}

resource "aws_iam_user" "admin" {
  name = "admin"
}

resource "aws_iam_user_login_profile" "admin" {
  user                    = aws_iam_user.admin.name
  password_reset_required = false
}

output "admin_password" {
  value     = aws_iam_user_login_profile.admin.password
  sensitive = true
}

resource "aws_iam_user_policy_attachment" "admin_administrator_access" {
  user       = aws_iam_user.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}