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
# Security Group para ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-dev"
  description = "Allow HTTP and HTTPS access to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg-dev"
  }
}

# Public Subnets
resource "aws_subnet" "public-dev-a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.12.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-dev-a"
  }
}

resource "aws_subnet" "public-dev-b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.13.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-dev-b"
  }
}

# Private Subnets
resource "aws_subnet" "private-dev-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-dev-a"
  }
}

resource "aws_subnet" "private-dev-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-dev-b"
  }
}

# NAT Gateway + EIP por ambiente
resource "aws_eip" "nat_dev" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_dev" {
  allocation_id = aws_eip.nat_dev.id
  subnet_id     = aws_subnet.public-dev-a.id
  tags = {
    Name = "nat-dev"
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

resource "aws_route_table_association" "public-dev-a" {
  subnet_id      = aws_subnet.public-dev-a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-dev-b" {
  subnet_id      = aws_subnet.public-dev-b.id
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

resource "aws_route_table_association" "private-dev-a" {
  subnet_id      = aws_subnet.private-dev-a.id
  route_table_id = aws_route_table.private-dev.id
}

resource "aws_route_table_association" "private-dev-b" {
  subnet_id      = aws_subnet.private-dev-b.id
  route_table_id = aws_route_table.private-dev.id
}

# ALB para dev
resource "aws_lb" "alb_dev" {
  name               = "alb-dev"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public-dev-a.id, aws_subnet.public-dev-b.id]

  tags = {
    Environment = "dev"
  }
}
