output "vpc_id" {
  value = aws_vpc.this.id
}

# якщо твої сабнети названі aws_subnet.public та aws_subnet.private
output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}
