provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "vpc-${var.environment}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw-${var.environment}"
  }
}

# Subnets
resource "aws_subnet" "dev" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-dev"
  }
}

resource "aws_subnet" "prod" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-prod"
  }
}

resource "aws_subnet" "test" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.3.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-test"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "rt-${var.environment}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Asociaciones de Route Tables
resource "aws_route_table_association" "dev" {
  subnet_id      = aws_subnet.dev.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "prod" {
  subnet_id      = aws_subnet.prod.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "test" {
  subnet_id      = aws_subnet.test.id
  route_table_id = aws_route_table.main.id
}

