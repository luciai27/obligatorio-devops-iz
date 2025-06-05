terraform {
  backend "s3" {
    bucket         = "votting-app-terraform-states"
#    key            = "infra/${var.environment}.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
