
variable "app_name" {
  type        = string
  description = "Application Name"
  default     = "techscrum"
}

variable "app_environment_uat" {
  type        = string
  description = "Application Environment"
}

variable "app_environment_prod" {
  type        = string
  description = "Application Environment"
}

variable "uat_vpc_id" {
  description = "uat vpc id"
  type        = string
}

variable "prod_vpc_id" {
  description = "prod vpc id"
  type        = string
}

variable "port" {
  description = "The starting port for a range of ports"
  type        = number
  #   default     = 8000
}