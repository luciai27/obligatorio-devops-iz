cluster_name = "eks-voting_app-dev"
public_subnet_cidrs    = ["192.168.13.0/24", "192.168.14.0/24"]
environment = "dev"
node_group_name= "voting_app-dev-ng"
bucket         = "voting_app-states"
key            = "dev/terraform.tfstate"
