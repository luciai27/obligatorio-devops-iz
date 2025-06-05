terraform {
  backend "s3" {
    bucket         = "votting-app-terraform-states"
    region         = "us-east-1"
    key            = "infra/prod.tfstate"
#    dynamodb_table = "terraform-lock"
  }
}
