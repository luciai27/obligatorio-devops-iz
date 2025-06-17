cluster_name = "eks-voting_app-test"
public_subnet_cidrs    = ["192.168.15.0/24", "192.168.16.0/24"]
environment = "test"
node_group_name= "voting_app-test-ng"
bucket         = "voting_app-states"
key            = "test/terraform.tfstate"