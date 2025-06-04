provider "aws" {
  region     = "us-east-1"
}

module "network" {
  source      = "../../modules/network"
  vpc_cidr    = "192.168.0.0/16"
  subnet_cidr = "192.168.2.0/24"
  env         = "dev"
}

