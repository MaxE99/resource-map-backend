# ========================================================================================================================
# Route53
# ========================================================================================================================

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain
  validation_method = "DNS"

  tags = var.tags
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = var.zone_id

  depends_on = [aws_acm_certificate.main]
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  depends_on = [aws_route53_record.validation]
}

# ========================================================================================================================
# API Gateway Domain
# ========================================================================================================================

resource "aws_apigatewayv2_domain_name" "api_gateway" {
  count = var.enable_api_gateway_domain ? 1 : 0

  domain_name = var.domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.main.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_acm_certificate.main, aws_acm_certificate_validation.main]
}

resource "aws_route53_record" "api_gateway_record" {
  count = var.enable_api_gateway_domain ? 1 : 0

  name    = aws_apigatewayv2_domain_name.api_gateway[0].domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api_gateway[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_gateway[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_apigatewayv2_domain_name.api_gateway]
}