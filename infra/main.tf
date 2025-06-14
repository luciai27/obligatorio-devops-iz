# VPC
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
 
  tags = {
    Name = "main-vpc"
  }
}
 
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
 
  tags = {
    Name = "main-igw"
  }
}
 
# Public Subnets
resource "aws_subnet" "public-dev" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.12.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public-dev"
  }
}
 
resource "aws_subnet" "public-test" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.13.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public-test"
  }
}
 
resource "aws_subnet" "public-prod" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.11.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public-prod"
  }
}
 
# Private Subnets
resource "aws_subnet" "private-dev" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1a"
 
  tags = {
    Name = "private-dev"
  }
}
 
resource "aws_subnet" "private-test" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "us-east-1b"
 
  tags = {
    Name = "private-test"
  }
}
 
resource "aws_subnet" "private-prod" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1c"
 
  tags = {
    Name = "private-prod"
  }
}
 
# NAT Gateway + EIP por ambiente
resource "aws_eip" "nat_dev" {
  domain = "vpc"
}
 
resource "aws_nat_gateway" "nat_dev" {
  allocation_id = aws_eip.nat_dev.id
  subnet_id     = aws_subnet.public-dev.id
  tags = {
    Name = "nat-dev"
  }
}
 
resource "aws_eip" "nat_test" {
  domain = "vpc"
}
 
resource "aws_nat_gateway" "nat_test" {
  allocation_id = aws_eip.nat_test.id
  subnet_id     = aws_subnet.public-test.id
  tags = {
    Name = "nat-test"
  }
}
 
resource "aws_eip" "nat_prod" {
  domain = "vpc"
}
 
resource "aws_nat_gateway" "nat_prod" {
  allocation_id = aws_eip.nat_prod.id
  subnet_id     = aws_subnet.public-prod.id
  tags = {
    Name = "nat-prod"
  }
}
 
# Route Tables y asociaciones
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
 
  tags = {
    Name = "public-rt"
  }
}
 
resource "aws_route_table_association" "public-dev" {
  subnet_id      = aws_subnet.public-dev.id
  route_table_id = aws_route_table.public.id
}
 
resource "aws_route_table_association" "public-test" {
  subnet_id      = aws_subnet.public-test.id
  route_table_id = aws_route_table.public.id
}
 
resource "aws_route_table_association" "public-prod" {
  subnet_id      = aws_subnet.public-prod.id
  route_table_id = aws_route_table.public.id
}
 
resource "aws_route_table" "private-dev" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_dev.id
  }
 
  tags = {
    Name = "private-dev-rt"
  }
}
 
resource "aws_route_table" "private-test" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_test.id
  }
 
  tags = {
    Name = "private-test-rt"
  }
}
 
resource "aws_route_table" "private-prod" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_prod.id
  }
 
  tags = {
    Name = "private-prod-rt"
  }
}
 
resource "aws_route_table_association" "private-dev" {
  subnet_id      = aws_subnet.private-dev.id
  route_table_id = aws_route_table.private-dev.id
}
 
resource "aws_route_table_association" "private-test" {
  subnet_id      = aws_subnet.private-test.id
  route_table_id = aws_route_table.private-test.id
}
 
resource "aws_route_table_association" "private-prod" {
  subnet_id      = aws_subnet.private-prod.id
  route_table_id = aws_route_table.private-prod.id
}