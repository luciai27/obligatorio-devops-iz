terraform {
  backend "s3" {}
}

resource "aws_vpc" "shared" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
 
  tags = {
    Name = "voting_app-vpc"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.shared.id
  tags = {
    Name = "voting_app-igw"
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "voting_app-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "${path.module}/voting_app-key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}