resource "aws_route53_zone" "_zone" {
  count = var.bootstrap_step == 1 && var.route53_zone_id == "" ? 1 : 0
  name  = var.matrix_domain

  tags = {
    Name = "${local.task_name}-route53-zone"
  }
}

data "aws_route53_zone" "zone" {
  zone_id = var.route53_zone_id != "" ? var.route53_zone_id : aws_route53_zone._zone[0].zone_id
}

resource "aws_route53_record" "alb" {
  count = var.bootstrap_step >= 1 ? 1 : 0

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "alb.${var.matrix_domain}"
  type    = "CNAME"
  ttl     = 300

  records = [data.aws_lb.alb.dns_name]
}

resource "aws_route53_record" "matrix_synapse_a" {
  count = var.bootstrap_step >= 3 ? 1 : 0

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "synapse.${var.matrix_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this[0].domain_name
    zone_id                = aws_cloudfront_distribution.this[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "matrix_synapse_aaaa" {
  count = var.bootstrap_step >= 3 ? 1 : 0

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "synapse.${var.matrix_domain}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this[0].domain_name
    zone_id                = aws_cloudfront_distribution.this[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "matrix_web_a" {
  count = var.bootstrap_step >= 3 ? 1 : 0

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "chat.${var.matrix_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.web[0].domain_name
    zone_id                = aws_cloudfront_distribution.web[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "matrix_web_aaaa" {
  count = var.bootstrap_step >= 3 ? 1 : 0

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "chat.${var.matrix_domain}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.web[0].domain_name
    zone_id                = aws_cloudfront_distribution.web[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "matrix_mas_a" {
  count = var.bootstrap_step >= 3 ? 1 : 0

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "account.${var.matrix_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.mas[0].domain_name
    zone_id                = aws_cloudfront_distribution.mas[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "matrix_mas_aaaa" {
  count = var.bootstrap_step >= 3 ? 1 : 0

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "account.${var.matrix_domain}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.mas[0].domain_name
    zone_id                = aws_cloudfront_distribution.mas[0].hosted_zone_id
    evaluate_target_health = false
  }
}
