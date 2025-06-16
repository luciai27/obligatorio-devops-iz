cluster_name = "eks-prd"
public_subnet_cidrs    = ["192.168.11.0/24", "192.168.12.0/24"]
private_subnet_cidrs   = ["192.168.1.0/24", "192.168.2.0/24"]
environment = "dev"

cluster_name = "eks-dev"
public_subnet_cidrs    = ["192.168.13.0/24", "192.168.14.0/24"]
private_subnet_cidrs   = ["192.168.3.0/24", "192.168.4.0/24"]
environment = "dev"

cluster_name = "eks-test"
public_subnet_cidrs    = ["192.168.15.0/24", "192.168.16.0/24"]
private_subnet_cidrs   = ["192.168.5.0/24", "192.168.6.0/24"]
environment = "dev"
