//create alb
resource "aws_lb" "alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.prod_public_subnet_ids
  enable_http2       = true

  idle_timeout = 60
  ///create bucket for alb logs
  access_logs {
    bucket  = var.backend_bucket.id
    prefix  = "${var.app_name}-alb-access-logs"
    enabled = true
  }
  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.app_environment_prod
  }
}

resource "aws_lb_target_group" "tg_prod" {
  name        = "${var.app_name}-target-group-${var.app_environment_prod}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.prod_vpc_id
  target_type = "ip"

  health_check {
    interval            = 200
    path                = var.health_check_path
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
  tags = {
    Name        = "${var.app_name}-target-group-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" // or another policy if needed
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_prod.arn
  }
  tags = {
    Name        = "${var.app_name}-lb-listener"
    Environment = var.app_environment_prod
  }
}

resource "aws_lb_listener_rule" "https_prod" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_prod.arn
  }

  condition {
    host_header {
      values = ["prod.${var.domain_name}"]
    }
  }
}