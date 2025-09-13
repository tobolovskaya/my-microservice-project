# Виведення інформації про VPC

output "vpc_id" {
  description = "ID VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR блок VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "ID публічних підмереж"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "ID приватних підмереж"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "ID route table для публічних підмереж"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "ID route tables для приватних підмереж"
  value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
  description = "ID NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}