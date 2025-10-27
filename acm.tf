### --- ALB Certificate ---

resource "aws_acm_certificate" "alb_cert" {
  count             = var.bootstrap_step >= 2 ? 1 : 0
  domain_name       = "alb.${var.matrix_domain}"
  validation_method = "DNS"

  tags = {
    Name = "${local.task_name}-alb-cert"
  }
}

resource "aws_route53_record" "alb_validation" {
  for_each = {
    for dvo in(var.bootstrap_step >= 2 ? aws_acm_certificate.alb_cert[0].domain_validation_options : []) : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.zone.zone_id
}

### --- CloudFront Certificate ---
# This will need to be created in the us-east-1 region for CloudFront

resource "aws_acm_certificate" "cloudfront_cert" {
  count       = var.bootstrap_step >= 2 ? 1 : 0
  domain_name = "synapse.${var.matrix_domain}"
  subject_alternative_names = [
    "account.${var.matrix_domain}",
    "admin.${var.matrix_domain}",
    "chat.${var.matrix_domain}",
    "mrtc.${var.matrix_domain}"
  ]
  validation_method = "DNS"

  # this is set in the providers block when calling this module
  provider = aws.us-east-1

  tags = {
    Name = "${local.task_name}-cloudfront-certificate"
  }
}

resource "aws_route53_record" "cloudfront_validation" {
  for_each = {
    for dvo in(var.bootstrap_step >= 2 ? aws_acm_certificate.cloudfront_cert[0].domain_validation_options : []) : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.zone.zone_id
}