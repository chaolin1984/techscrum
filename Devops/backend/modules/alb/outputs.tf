output "tg_prod_arn" {
  description = "tg prod arn"
  value       = aws_lb_target_group.tg_prod.arn
}

output "listener_arn" {
  description = "The ARN of the listener"
  value       = aws_lb_listener.https_listener.arn
}

output "alb_dns_name" {
  description = "alb dns name"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "alb zone id"
  value       = aws_lb.alb.zone_id
}

output "alb_arn_suffix" {
  description = "alb arn suffix"
  value       = aws_lb.alb.arn_suffix
}


