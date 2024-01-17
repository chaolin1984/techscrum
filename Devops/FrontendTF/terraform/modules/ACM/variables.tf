variable "domain_name" {
  type        = string
  description = "The domain name to use"
  default     = "www.tecscrum.com"
}

variable "hostzone_name" {
  type        = string
  description = "The hostzone name"
  default     = "tecscrum.com"
}

variable "asterisk_domain_name" {
  type        = string
  description = "The domain name to use"
  default     = "*.tecscrum.com"
}