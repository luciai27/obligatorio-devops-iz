variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  description = "Ambiente a desplegar (dev, test, prod)"
  type        = string
}
