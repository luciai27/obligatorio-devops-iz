provider "aws" {
  region = "${var.region}"
}

data "aws_vpc" "shared" {
  filter {
    name   = "tag:Name"
    values = ["shared-vpc"]
  }
}

data "aws_internet_gateway" "shared" {
  filter {
    name   = "tag:Name"
    values = ["shared-igw"]
  }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = data.aws_vpc.shared.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public_${var.environment}_1"
  }
}
 
resource "aws_subnet" "public_dev_2" {
  vpc_id                  = data.aws_vpc.shared.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public_dev_2"
  }
}
 
# Private Subnets
resource "aws_subnet" "private_dev_1" {
  vpc_id            = data.aws_vpc.shared.id
  cidr_block        = var.public_subnet_cidrs[0]
  availability_zone = "${var.region}a"
 
  tags = {
    Name = "private_dev_1"
  }
}
 
resource "aws_subnet" "private_dev_2" {
  vpc_id            = data.aws_vpc.shared.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = "${var.region}b"
 
  tags = {
    Name = "private_dev_2"
  }
}
 
# NAT Gateway + EIP 
resource "aws_eip" "nat_dev_1" {
  domain = "vpc"
}
 
resource "aws_nat_gateway" "nat_dev_1" {
  allocation_id = aws_eip.nat_dev_1.id
  subnet_id     = aws_subnet.public_dev_1.id
  tags = {
    Name = "nat_dev_1"
  }
}
 
resource "aws_eip" "nat_dev_2" {
  domain = "vpc"
}
 
resource "aws_nat_gateway" "nat_dev_2" {
  allocation_id = aws_eip.nat_dev_2.id
  subnet_id     = aws_subnet.public_dev_2.id
  tags = {
    Name = "nat_dev_2"
  }
}
 
# Route Tables y asociaciones
resource "aws_route_table" "public_dev" {
  vpc_id = data.aws_vpc.shared.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
 
  tags = {
    Name = "public-dev-rt"
  }
}
 
resource "aws_route_table_association" "public_dev_1" {
  subnet_id      = aws_subnet.public_dev_1.id
  route_table_id = aws_route_table.public_dev.id
}
 
resource "aws_route_table_association" "public_dev_2" {
  subnet_id      = aws_subnet.public_dev_2.id
  route_table_id = aws_route_table.public_dev.id
}
  
resource "aws_route_table" "private_dev_1" {
  vpc_id = data.aws_vpc.shared.id
 
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_dev_1.id
  }
 
  tags = {
    Name = "private_dev_1-rt"
  }
}
 
resource "aws_route_table" "private_dev_2" {
  vpc_id = data.aws_vpc.shared.id
 
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_dev_2.id
  }
 
  tags = {
    Name = "private_dev_2-rt"
  }
}
 
 
resource "aws_route_table_association" "private_dev_1" {
  subnet_id      = aws_subnet.private_dev_1.id
  route_table_id = aws_route_table.private_dev_1.id
}
 
resource "aws_route_table_association" "private_dev_2" {
  subnet_id      = aws_subnet.private_dev_2.id
  route_table_id = aws_route_table.private_dev_2.id
}

 
# ALBs por ambiente
resource "aws_lb" "alb_dev_1" {
  name               = "alb_dev_1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [] # definir sg después
  subnets            = [aws_subnet.public_dev_1.id]
 
  tags = {
    Environment = "alb_dev_1"
  }
}
 
resource "aws_lb" "alb_dev_2" {
  name               = "alb_dev_2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [] # definir sg después
  subnets            = [aws_subnet.public_dev_2.id]
 
  tags = {
    Environment = "alb_dev_2"
  }
}

resource "aws_eks_cluster" "cluster" {
  name     = "eks-dev"
  role_arn = arn:aws:iam::330090896481:role/LabRole

  vpc_config {
    subnet_ids = [
      aws_subnet.private_dev_1.id,
      aws_subnet.private_dev_2.id,
      aws_subnet.public_dev_1.id,
      aws_subnet.public_dev_2.id
    ]
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "ng-dev"
  node_role_arn   = arn:aws:iam::330090896481:role/LabRole
  subnet_ids      = [
      aws_subnet.private_dev_1.id,
      aws_subnet.private_dev_2.id,
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"
}

# Security group de nodos
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "Permite comunicación nodo-nodo y del control plane"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Node-to-node"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Control plane to kubelet"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id] #PREGUNTAR A CHAT
  }

  ingress {
    description = "DNS entre nodos"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}

# Launch Template
resource "aws_launch_template" "eks_nodes_lt" {
  name_prefix   = "eks-nodes-"
  image_id      = ami-0db36bcbb6bf68b98 # Pasarlo a data?
  instance_type = "t3.medium"

  vpc_security_group_ids = [aws_security_group.eks_nodes_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                        = "eks-node"
      "kubernetes.io/cluster/eks-dev" = "owned"
    }
  }
}

# Node group launch template
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "ng-dev"
  node_role_arn   = data.aws_iam_role.node.arn

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  launch_template {
    id      = aws_launch_template.eks_nodes_lt.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  ami_type      = "AL2_x86_64"     # no se usa con launch template, pero es obligatorio
  capacity_type = "ON_DEMAND"
}