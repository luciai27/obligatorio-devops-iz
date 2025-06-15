
output "vpc_id" {
  value = aws_vpc.shared.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}