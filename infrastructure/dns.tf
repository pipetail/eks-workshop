resource "aws_route53_zone" "this" {
  name = "workshop.eks.rocks"
}

output "name_servers" {
  value = aws_route53_zone.this.name_servers
}

resource "aws_acm_certificate" "wildcard" {
  domain_name       = "*.${aws_route53_zone.this.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_validation : record.fqdn]
}

resource "aws_route53_record" "app1" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "app1.${aws_route53_zone.this.name}"
  type    = "A"

  alias {
    name                   = aws_alb.nginx_ingress.dns_name
    zone_id                = aws_alb.nginx_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app2" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "app2.${aws_route53_zone.this.name}"
  type    = "A"

  alias {
    name                   = aws_alb.nginx_ingress.dns_name
    zone_id                = aws_alb.nginx_ingress.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app3" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "app3.${aws_route53_zone.this.name}"
  type    = "A"

  alias {
    name                   = aws_alb.nginx_ingress.dns_name
    zone_id                = aws_alb.nginx_ingress.zone_id
    evaluate_target_health = false
  }
}
