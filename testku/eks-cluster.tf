resource "aws_eks_cluster" "eks_dev" {
  name     = var.cluster_name
  version  = "1.31"
  role_arn = "arn:aws:iam::186478816830:role/LabRole"

  vpc_config {
    subnet_ids = [
      aws_subnet.private-dev-a.id, 
      aws_subnet.private-dev-b.id
    ]
  }

  access_config {
    authentication_mode = "API"
  }

  tags = {
    Environment = "dev"
    Name        = var.cluster_name
  }
}
