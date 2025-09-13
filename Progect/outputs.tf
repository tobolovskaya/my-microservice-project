# Загальні виводи ресурсів

# VPC виводи
output "vpc_id" {
  description = "ID VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "ID приватних підмереж"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "ID публічних підмереж"
  value       = module.vpc.public_subnet_ids
}

# RDS виводи
output "database_endpoint" {
  description = "Endpoint бази даних"
  value       = module.rds.endpoint
}

output "database_port" {
  description = "Порт бази даних"
  value       = module.rds.port
}

output "database_name" {
  description = "Назва бази даних"
  value       = module.rds.database_name
}

output "database_username" {
  description = "Ім'я користувача бази даних"
  value       = module.rds.username
  sensitive   = true
}

output "security_group_id" {
  description = "ID Security Group для бази даних"
  value       = module.rds.security_group_id
}

output "subnet_group_name" {
  description = "Назва DB Subnet Group"
  value       = module.rds.subnet_group_name
}

output "parameter_group_name" {
  description = "Назва Parameter Group"
  value       = module.rds.parameter_group_name
}