variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  type        = string
  description = "Nombre del cluster EKS"
}

variable "vpc_cidr" {
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}
variable "environment" {
    type = string
}