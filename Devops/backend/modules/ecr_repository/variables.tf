
variable "app_name" {
  type        = string
  description = "Application Name"
}
variable "ecr_images_number" {
  description = "The starting port for a range of ports"
  type        = number
}