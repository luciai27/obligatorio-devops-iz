data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

terraform {
  backend "s3" {}
}

data "aws_vpc" "shared" {
  filter {
    name   = "tag:Name"
    values = ["voting_app-vpc"]
  }
}

data "aws_internet_gateway" "shared" {
  filter {
    name   = "tag:Name"
    values = ["voting_app-igw"]
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = data.aws_vpc.shared.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${data.aws_vpc.shared.tags.Name}-public-${count.index + 1}"
  }
}


resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.shared.id

  tags = {
    Name = "${data.aws_vpc.shared.tags.Name}-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.shared.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = var.aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
