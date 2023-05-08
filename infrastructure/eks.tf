data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "workshop"
  cluster_version = "1.26"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  self_managed_node_group_defaults = {
    instance_type                          = "t3.medium"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  self_managed_node_groups = {
    one = {
      name         = "main-1"
      max_size     = 5
      desired_size = 2

      tags = {
        "k8s.io/cluster-autoscaler/enabled"  = "true"
        "k8s.io/cluster-autoscaler/workshop" = "owned"
      }

      target_group_arns = [
        aws_alb_target_group.nginx_ingress_http.arn,
      ]
    }

    two = {
      name          = "main-2"
      instance_type = "m5a.large"
      max_size      = 1
      min_size      = 0
      desired_size  = 0
      tags = {
        "k8s.io/cluster-autoscaler/node-template/label/size" = "large"
      }
      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=size=large'"
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true
  create_aws_auth_configmap = true

  # administrator don't have to be configured in roles,
  # instead, he only needs to assume role and access
  # the cluster
  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_access_administrator.arn,
      username = "administrator:{{SessionName}}"
      groups = [
        "system:masters",
      ]
    },
  ]

  # map student to viewonly group, check kubernetes.tf for more
  # details regarding the clusterrole assignment
  aws_auth_users = [
    {
      userarn  = aws_iam_user.student.arn
      username = aws_iam_user.student.name
      groups = [
        "viewonly",
      ]
    },
    {
      userarn  = aws_iam_user.admin.arn
      username = aws_iam_user.admin.name
      groups = [
        "system:masters",
      ]
    },
  ]
}

# temporary fix: allow all self communication
# without this nodeports were not functioning properly
# this is most likely some issue in EKS module since
# there use to be similar rule in module configured
resource "aws_security_group_rule" "eks_workers_to_eks_workers_all" {
  type                     = "ingress"
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks.node_security_group_id
  from_port                = 0
  security_group_id        = module.eks.node_security_group_id
}