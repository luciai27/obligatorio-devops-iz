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