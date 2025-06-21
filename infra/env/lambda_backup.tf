variable "environment" {}
variable "eks_cluster_name" {}
variable "backup_bucket" {}

resource "aws_lambda_function" "eks_backup" {
  function_name = "eks-backup-${var.environment}"
  role          = "arn:aws:iam::186478816830:role/LabRole"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
  timeout       = 300

  environment {
    variables = {
      CLUSTER_NAME = var.eks_cluster_name
      BUCKET_NAME  = secrets.BUCKET_NAME
      REGION       = "us-east-1"
    }
  }
}

resource "aws_ecr_repository" "lambda_repo" {
  name = "eks-backup-lambda"
}
