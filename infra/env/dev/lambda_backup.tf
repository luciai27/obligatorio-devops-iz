#resource "aws_lambda_function" "eks_backup" {
#  function_name = "eks-backup-${var.environment}"
#  role          = "arn:aws:iam::330090896481:role/LabRole"
#  package_type  = "Image"
#  image_uri     = "186478816830.dkr.ecr.us-east-1.amazonaws.com/lambda-backup:latest"
#  timeout       = 300
#
#  environment {
#    variables = {
#      CLUSTER_NAME = var.cluster_name
#      BUCKET_NAME  = var.backup_bucket
#      REGION       = "us-east-1"
#    }
#  }
#}

#resource "aws_ecr_repository" "lambda_repo" {
#  name = "lambda-backup"
#}

resource "aws_lambda_function" "check_health" {
  function_name = "check-health-${var.environment}"
  role          = data.aws_iam_role.lab_role.arn
  package_type  = "Image"
  image_uri     = "330090896481.dkr.ecr.us-east-1.amazonaws.com/lambda-healthcheck:latest"
  timeout       = 60

  environment {
    variables = {
      ALB           = var.alb_result
      AGLB2         = var.alb_vote
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}