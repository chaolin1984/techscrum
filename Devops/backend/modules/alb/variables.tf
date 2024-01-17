variable "app_name" {
  type        = string
  description = "Application Name"
}

variable "backend_bucket" {
  description = "backend_bucket"
}

variable "app_environment_uat" {
  type        = string
  description = "Application Environment"
}

variable "app_environment_prod" {
  type        = string
  description = "Application Environment"
  default     = "prod"
}

variable "health_check_path" {
  description = "target group health check path"
  type        = string
}

variable "alb_sg_id" {
  description = "alb sg id"
  type        = string
}

variable "prod_vpc_id" {
  description = "prod vpc id"
  type        = string
}

variable "prod_public_subnet_ids" {
  description = "List of IDs of public subnets"
  type        = list(string)
}

variable "domain_name" {
  description = "domain name"
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the certificate"
}