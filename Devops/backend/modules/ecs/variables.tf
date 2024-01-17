variable "app_name" {
  type        = string
  description = "Application Name"
}

variable "app_environment_uat" {
  type        = string
  description = "Application Environment"
}

variable "app_environment_prod" {
  type        = string
  description = "Application Environment"
}

variable "uat_public_subnet_ids" {
  description = "List of IDs of uat public subnets"
  type        = list(string)
}

variable "task_desired_count" {
  description = "desired count of tasks"
  type        = number
}

variable "task_min_count" {
  description = "min count of tasks"
  type        = number
}

variable "task_max_count" {
  description = "min count of tasks"
  type        = number
}

variable "port" {
  description = "The starting port for a range of ports"
  type        = number
}

variable "prod_private_subnet_ids" {
  description = "List of IDs of rpod private subnets"
  type        = list(string)
}

variable "uat_service_sg_id" {
  description = "service sg id"
  type        = string
}

variable "prod_service_sg_id" {
  description = "service sg id"
  type        = string
}
variable "repository_url" {
  description = "image repository url"
  type        = string
}


variable "tg_prod_arn" {
  description = "tg prod arn"
  type        = string
}

variable "listener_arn" {
  description = "ARN of the listener"
  type        = string
}