terraform {
  backend "s3" {
    bucket         = "votting-app-terraform-states"
    region         = "us-east-1"
    key            = "infra/test.tfstate"
#    dynamodb_table = "terraform-lock"
  }
}
