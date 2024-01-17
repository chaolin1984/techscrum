variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr_block_uat" {
  type        = string
  description = "cidr block  of uat vpc"
}

variable "vpc_cidr_block_prod" {
  type        = string
  description = "cidr block  of prod vpc"
}

variable "public_subnets_uat" {
  type        = list(string)
  description = "List of uat public subnets"
}

variable "public_subnets_prod" {
  type        = list(string)
  description = "List of prod public subnets"
}

variable "private_subnets_prod" {
  type        = list(string)
  description = "List of prod private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

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

