resource "aws_security_group" "alb_nginx_ingress" {
  name   = "alb_nginx_ingress"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "alb_nginx_ingress_egress_all" {
  type     = "egress"
  to_port  = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port         = 0
  security_group_id = aws_security_group.alb_nginx_ingress.id
}

resource "aws_security_group_rule" "alb_nginx_ingress_ingress_80" {
  type     = "ingress"
  to_port  = 80
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port         = 80
  security_group_id = aws_security_group.alb_nginx_ingress.id
}

resource "aws_security_group_rule" "alb_nginx_ingress_ingress_443" {
  type     = "ingress"
  to_port  = 443
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  from_port         = 443
  security_group_id = aws_security_group.alb_nginx_ingress.id
}

# allow ALB to EKS communication
resource "aws_security_group_rule" "alb_nginx_ingress_to_eks_http" {
  type                     = "ingress"
  to_port                  = local.nginx_ingress_ports["http"]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_nginx_ingress.id
  from_port                = local.nginx_ingress_ports["http"]
  security_group_id        = module.eks.node_security_group_id
}

resource "aws_alb" "nginx_ingress" {
  name               = "nginx-ingress"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups = [
    aws_security_group.alb_nginx_ingress.id,
  ]
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  idle_timeout = 10
}

resource "aws_alb_target_group" "nginx_ingress_http" {
  name_prefix = "nginx"
  port        = local.nginx_ingress_ports["http"]
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = "/healthz"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.nginx_ingress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.nginx_ingress.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.wildcard.certificate_arn

  ssl_policy = "ELBSecurityPolicy-FS-1-2-2019-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.nginx_ingress_http.arn
  }
}