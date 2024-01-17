variable "app_name" {
  description = "application name"
  type        = string
}

variable "sns_email" {
  description = "sns email"
  type        = string
}

variable "app_environment_uat" {
  type        = string
  description = "Application Environment"
}

variable "app_environment_prod" {
  type        = string
  description = "Application Environment"
}

variable "alb_arn_suffix" {
  description = "alb arn suffix"
}
