resource "aws_lambda_function" "eks_backup" {
  function_name = "eks-backup-${var.environment}"
  role          = "arn:aws:iam::186478816830:role/LabRole"
  package_type  = "Image"
  image_uri     = "186478816830.dkr.ecr.us-east-1.amazonaws.com/lambda-backup:latest"
  timeout       = 300

  environment {
    variables = {
      CLUSTER_NAME = var.cluster_name
      BUCKET_NAME  = var.backup_bucket
      REGION       = "us-east-1"
    }
  }
}

resource "aws_ecr_repository" "lambda_repo" {
  name = "lambda-backup"
}
