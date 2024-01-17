output "uat_vpc_id" {
  description = "The id of the uat VPC"
  value       = aws_vpc.vpc_uat.id
}

output "prod_vpc_id" {
  description = "The id of the prod VPC"
  value       = aws_vpc.vpc_prod.id
}

output "uat_public_subnet_ids" {
  description = "List of IDs of uat public subnets"
  value       = aws_subnet.techscrum-public-subnet-uat.*.id
}

output "prod_public_subnet_ids" {
  description = "List of IDs of prod public subnets"
  value       = aws_subnet.techscrum-public-subnet-prod.*.id
}

output "prod_private_subnet_ids" {
  description = "List of IDs of prod private subnets"
  value       = aws_subnet.techscrum-private-subnet-prod.*.id
}
