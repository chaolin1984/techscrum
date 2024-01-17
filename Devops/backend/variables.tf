variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "vpc_cidr_block_uat" {
  type        = string
  description = "cidr block  of uat vpc"
  default     = "11.0.0.0/16"
}

variable "vpc_cidr_block_prod" {
  type        = string
  description = "cidr block  of prod vpc"
  default     = "12.0.0.0/16"
}

variable "public_subnets_uat" {
  type        = list(string)
  description = "List of uat public subnets"
  default     = ["11.0.0.0/20", "11.0.16.0/20"]
}

variable "public_subnets_prod" {
  type        = list(string)
  description = "List of prod public subnets"
  default     = ["12.0.0.0/20", "12.0.16.0/20"]
}

variable "private_subnets_prod" {
  type        = list(string)
  description = "List of prod private subnets"
  default     = ["12.0.128.0/20", "12.0.144.0/20"]
}
variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "app_name" {
  type        = string
  description = "Application Name"
  default     = "techscrum"
}

variable "app_environment_uat" {
  type        = string
  description = "Application Environment"
  default     = "uat"
}

variable "app_environment_prod" {
  type        = string
  description = "Application Environment"
  default     = "prod"
}

variable "health_check_path" {
  description = "target group health check path"
  type        = string
  default     = "/api/v2/healthcheck"
}

variable "port" {
  description = "The starting port for a range of ports"
  type        = number
  default     = 8000
}

variable "ecr_images_number" {
  description = "The starting port for a range of ports"
  type        = number
  default     = 5
}
variable "task_desired_count" {
  description = "desired count of tasks"
  type        = number
  default     = 2
}

variable "task_min_count" {
  description = "min count of tasks"
  type        = number
  default     = 2
}

variable "task_max_count" {
  description = "min count of tasks"
  type        = number
  default     = 4
}

variable "domain_name" {
  description = "domain name"
  type        = string
  default     = "tecscrum.com"
}

variable "sns_email" {
  description = "sns email"
  type        = string
  default     = "devopstechscrum@outlook.com"
}

variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
  default     = "techscrum-alb-log-bucket"
}
