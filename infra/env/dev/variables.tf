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
 
variable "environment" {
    type = string
}

variable "availability_zones" {
  description = "The availability zones for the VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "node_group_name" {
  description = "The name of the EKS node group"
  type        = string
}
variable "backup_bucket" {
  description = "The name of the S3 bucket for backups"
  type        = string
  default     = "votingapp-states"
}

