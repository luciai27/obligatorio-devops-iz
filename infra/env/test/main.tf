data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

terraform {
  backend "s3" {}
}

data "aws_vpc" "shared" {
  filter {
    name   = "tag:Name"
    values = ["voting_app-vpc"]
  }
}

data "aws_internet_gateway" "shared" {
  filter {
    name   = "tag:Name"
    values = ["voting_app-igw"]
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = data.aws_vpc.shared.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${data.aws_vpc.shared.tags.Name}-public-${var.environment}-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.shared.id

  tags = {
    Name = "${data.aws_vpc.shared.tags.Name}-public-${var.environment}-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.shared.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}



resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  tags = {
    Name = var.cluster_name
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]
  ami_type       = "AL2_x86_64"

  tags = {
    Name = var.node_group_name
  }

  depends_on = [aws_eks_cluster.eks]
}

resource "aws_lambda_function" "eks_backup" {
  function_name = "eks-backup-${var.environment}"
  role          = data.aws_iam_role.lab_role.arn

  package_type  = "Image"
  image_uri     = "186478816830.dkr.ecr.us-east-1.amazonaws.com/lambda-backup:${var.environment}"

  timeout       = 900
  memory_size   = 256

  environment {
    variables = {
      CLUSTER_NAME = "voting-app-${var.environment}-cluster"
      BUCKET_NAME  = secrets.BUCKET_NAME
      REGION       = secrets.aws_region
    }
  }
}
