data "aws_route53_zone" "main" {
  name       = "codedevops.cloud." # Ensure the domain name ends with a dot
  depends_on = [aws_route53_zone.main]
}
resource "aws_route53_zone" "main" {
  name = "codedevops.cloud"
}
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.codedevops.cloud"
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}
resource "aws_acm_certificate" "example_cert" {
  domain_name       = "www.codedevops.cloud"
  validation_method = "DNS"

  subject_alternative_names = ["*.codedevops.cloud"]

  tags = {
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.example_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "example_cert" {
  certificate_arn         = aws_acm_certificate.example_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  depends_on              = [aws_route53_record.cert_validation]

}
