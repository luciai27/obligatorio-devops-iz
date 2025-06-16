# Launch Template para Node Group
resource "aws_launch_template" "eks_dev_lt" {
  name_prefix   = "eks-dev-lt-"
  image_id      = data.aws_ami.eks_worker_ami.id
  instance_type = "t3.medium"
  key_name      = "vockey"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.eks_nodes.id]
  }
  
  user_data = base64encode(<<EOT
  #!/bin/bash
  set -o xtrace
  /etc/eks/bootstrap.sh ${aws_eks_cluster.eks_dev.name}
  EOT
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "eks-dev-node"
      Environment = "dev"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# AMI para EKS workers (usando la misma región)
data "aws_ami" "eks_worker_ami" {
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI owner

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.31-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group para los nodos del cluster
resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
  description = "SG para nodos EKS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
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
    Name = "eks-nodes-sg"
  }
}

# Node Group con Launch Template
resource "aws_eks_node_group" "dev_nodes" {
  cluster_name    = aws_eks_cluster.eks_dev.name
  node_group_name = "dev-node-group"
  node_role_arn   = "arn:aws:iam::186478816830:role/LabRole"

  subnet_ids = [
    aws_subnet.private-dev-a.id,
    aws_subnet.private-dev-b.id
  ]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.eks_dev_lt.id
    version = "$Latest"
  }

  tags = {
    Name        = "eks-dev-nodes"
    Environment = "dev"
  }

  depends_on = [aws_launch_template.eks_dev_lt]
}
