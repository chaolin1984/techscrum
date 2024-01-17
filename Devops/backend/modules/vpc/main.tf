#create two vpc, 1 for uat, 1 for prod
resource "aws_vpc" "vpc_uat" {
  cidr_block       = var.vpc_cidr_block_uat
  instance_tenancy = "default"

  tags = {
    Name        = "${var.app_name}-vpc-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
}

resource "aws_vpc" "vpc_prod" {
  cidr_block       = var.vpc_cidr_block_prod
  instance_tenancy = "default"

  tags = {
    Name        = "${var.app_name}-vpc-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

#create  aws internet gateway for each vpc
resource "aws_internet_gateway" "techscrum-internet-gateway-uat" {
  vpc_id = aws_vpc.vpc_uat.id
  tags = {
    Name        = "${var.app_name}-igw-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
}

resource "aws_internet_gateway" "techscrum-internet-gateway-prod" {
  vpc_id = aws_vpc.vpc_prod.id
  tags = {
    Name        = "${var.app_name}-igw-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

#  aws public subnets for uat
resource "aws_subnet" "techscrum-public-subnet-uat" {
  vpc_id                  = aws_vpc.vpc_uat.id
  cidr_block              = element(var.public_subnets_uat, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets_uat)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-public-subnet-${count.index + 1}-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
}

# aws public subnets for prod
resource "aws_subnet" "techscrum-public-subnet-prod" {
  vpc_id                  = aws_vpc.vpc_prod.id
  cidr_block              = element(var.public_subnets_prod, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  count                   = length(var.public_subnets_prod)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-public-subnet-${count.index + 1}-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}


# aws private sunbets for uat
resource "aws_subnet" "techscrum-private-subnet-prod" {
  vpc_id            = aws_vpc.vpc_prod.id
  count             = length(var.private_subnets_prod)
  cidr_block        = element(var.private_subnets_prod, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name        = "${var.app_name}-private-subnet-${count.index + 1}-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

# aws elastic ip address
resource "aws_eip" "nat_eip" {
  vpc   = true
  count = length(var.public_subnets_prod)

  tags = {
    Name        = "${var.app_name}-nat-eip-${count.index + 1}-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }

  depends_on = [aws_internet_gateway.techscrum-internet-gateway-prod]
}
# aws nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.techscrum-public-subnet-prod.*.id, count.index)
  count         = length(var.public_subnets_prod)

  tags = {
    Name        = "${var.app_name}-nat-gateway-${count.index + 1}"
    Environment = var.app_environment_prod
  }
}

# aws uat route table 
resource "aws_route_table" "techscrum-uat-rt" {
  vpc_id = aws_vpc.vpc_uat.id

  tags = {
    Name        = "${var.app_name}-routing-table-${var.app_environment_uat}"
    Environment = var.app_environment_uat
  }
}

# aws route for uat public subnets
resource "aws_route" "techscrum-uat" {
  route_table_id         = aws_route_table.techscrum-uat-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.techscrum-internet-gateway-uat.id
}

# aws uat public route table association
resource "aws_route_table_association" "uat-public" {
  count          = length(var.public_subnets_uat)
  subnet_id      = element(aws_subnet.techscrum-public-subnet-uat.*.id, count.index)
  route_table_id = aws_route_table.techscrum-uat-rt.id
}


# aws prod route table 
resource "aws_route_table" "techscrum-prod-public-rt" {
  vpc_id = aws_vpc.vpc_prod.id

  tags = {
    Name        = "${var.app_name}-routing-table-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

# aws route for prod public subnets
resource "aws_route" "techscrum-prod" {
  route_table_id         = aws_route_table.techscrum-prod-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.techscrum-internet-gateway-prod.id
}

# aws prod public route table association
resource "aws_route_table_association" "prod-public" {
  count          = length(var.public_subnets_prod)
  subnet_id      = element(aws_subnet.techscrum-public-subnet-prod.*.id, count.index)
  route_table_id = aws_route_table.techscrum-prod-public-rt.id
}

# aws route table for prod private subnet
resource "aws_route_table" "techscrum-prod-private-rt" {
  vpc_id = aws_vpc.vpc_prod.id
  count  = length(var.private_subnets_prod)

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gateway.*.id, count.index)
  }

  tags = {
    Name        = "${var.app_name}-routing-table-${count.index + 1}-${var.app_environment_prod}"
    Environment = var.app_environment_prod
  }
}

# aws prod private route table association
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_prod)
  subnet_id      = element(aws_subnet.techscrum-private-subnet-prod.*.id, count.index)
  route_table_id = element(aws_route_table.techscrum-prod-private-rt.*.id, count.index)
}

########################################################################################################
#                                     Create VPC Peering Connection
########################################################################################################
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = aws_vpc.vpc_prod.id
  vpc_id      = aws_vpc.vpc_uat.id
  auto_accept = false

  tags = {
    Name = "${var.app_name}-vpc-peering"
  }
}

# Accept the VPC Peering Connection on the peer (prod) VPC
resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept               = true

  tags = {
    Name = "${var.app_name}-vpc-peering-accepter"
  }
}

# Add route to UAT route tables to direct traffic destined for prod VPC 
resource "aws_route" "peer_route_uat" {
  route_table_id            = aws_route_table.techscrum-uat-rt.id
  destination_cidr_block    = aws_vpc.vpc_prod.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Add route to Prod public route table to direct traffic destined for uat VPC 
resource "aws_route" "peer_route_prod_public" {
  route_table_id            = aws_route_table.techscrum-prod-public-rt.id
  destination_cidr_block    = aws_vpc.vpc_uat.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Add route to Prod private route tables to direct traffic destined for uat VPC 
resource "aws_route" "peer_route_prod_private" {
  count                     = length(var.private_subnets_prod)
  route_table_id            = element(aws_route_table.techscrum-prod-private-rt.*.id, count.index)
  destination_cidr_block    = aws_vpc.vpc_uat.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}