variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  description = "Ambiente a desplegar (dev, test, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegarán los recursos"
  type        = string
  default = "aws_vpc.main.id"
  ## Se pone un valor, para que no se recree cada vez que se hace un merge o pr
}