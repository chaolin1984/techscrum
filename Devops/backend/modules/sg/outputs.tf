output "alb_sg_id" {
  description = "The alb sg id"
  value       = aws_security_group.alb_sg.id
}

output "uat_service_sg_id" {
  description = "The uat service sg id"
  value       = aws_security_group.service_sg_uat.id
}

output "prod_service_sg_id" {
  description = "The prod service sg id"
  value       = aws_security_group.service_sg_prod.id
}

