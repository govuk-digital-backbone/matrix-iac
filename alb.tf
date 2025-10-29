data "aws_lb" "alb" {
  arn = var.alb_arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 8008

  protocol        = var.bootstrap_step >= 3 ? "HTTPS" : "HTTP"
  ssl_policy      = var.bootstrap_step >= 3 ? "ELBSecurityPolicy-TLS-1-2-2017-01" : null
  certificate_arn = var.bootstrap_step >= 3 ? aws_acm_certificate.alb_cert[0].arn : null

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
      message_body = "Not found"
    }
  }
}

resource "aws_lb_listener_rule" "alb_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_synapse.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      values = ["synapse.${var.matrix_domain}"]
    }
  }

  dynamic "condition" {
    for_each = var.bootstrap_step >= 3 ? [1] : []
    content {
      http_header {
        http_header_name = "X-ALB-Protection"
        values           = [random_password.cloudfront_origin_header.result]
      }
    }
  }

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [
    aws_lb_target_group.alb_tg_synapse
  ]
}

resource "aws_lb_listener_rule" "alb_rule_web_client_json" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({
        "m.homeserver" : {
          "base_url" : "https://synapse.${var.matrix_domain}"
        },
        "org.matrix.msc2965.authentication" : {
          "issuer" : "https://account.${var.matrix_domain}/",
          "account" : "https://account.${var.matrix_domain}/account/"
        }
      })
      status_code = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/.well-known/matrix/client"]
    }
  }

  condition {
    host_header {
      values = ["synapse.${var.matrix_domain}"]
    }
  }

  dynamic "condition" {
    for_each = 1 == 0 ? [1] : []
    content {
      http_header {
        http_header_name = "X-ALB-Protection"
        values           = [random_password.cloudfront_origin_header.result]
      }
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_lb_target_group" "alb_tg_synapse" {
  name        = "${local.task_name}-tg-synapse"
  port        = 8008
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # Ensure listener rule is removed before TG
  lifecycle {
    create_before_destroy = false
  }

  health_check {
    path                = "/health"
    port                = "traffic-port" # use the port the container listens on
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 4
    matcher             = "200-299" # adjust as needed
  }
}

resource "aws_lb_listener_rule" "alb_rule_web" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_web.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      values = ["chat.${var.matrix_domain}"]
    }
  }

  dynamic "condition" {
    for_each = 1 == 0 ? [1] : []
    content {
      http_header {
        http_header_name = "X-ALB-Protection"
        values           = [random_password.cloudfront_origin_header.result]
      }
    }
  }

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [
    aws_lb_target_group.alb_tg_web
  ]
}

resource "aws_lb_listener_rule" "alb_rule_mas" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_mas.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      values = ["account.${var.matrix_domain}"]
    }
  }

  dynamic "condition" {
    for_each = 1 == 0 ? [1] : []
    content {
      http_header {
        http_header_name = "X-ALB-Protection"
        values           = [random_password.cloudfront_origin_header.result]
      }
    }
  }

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [
    aws_lb_target_group.alb_tg_mas
  ]
}

resource "aws_lb_target_group" "alb_tg_web" {
  name        = "${local.task_name}-tg-web"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # Ensure listener rule is removed before TG
  lifecycle {
    create_before_destroy = false
  }

  health_check {
    path                = "/config.json"
    port                = "traffic-port" # use the port the container listens on
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 4
    matcher             = "200-299" # adjust as needed
  }
}

resource "aws_lb_target_group" "alb_tg_mas" {
  name        = "${local.task_name}-tg-mas"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # Ensure listener rule is removed before TG
  lifecycle {
    create_before_destroy = false
  }

  health_check {
    path                = "/health"
    port                = "8081"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 4
    matcher             = "200-299" # adjust as needed
  }
}
