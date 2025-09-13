# Виводи RDS модуля

# Загальні виводи
output "endpoint" {
  description = "Endpoint бази даних"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].endpoint : null
  ) : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].endpoint : null
  )
}

output "reader_endpoint" {
  description = "Reader endpoint (тільки для Aurora)"
  value = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].reader_endpoint : null
}

output "port" {
  description = "Порт бази даних"
  value = local.default_port
}

output "database_name" {
  description = "Назва бази даних"
  value = var.database_name
}

output "username" {
  description = "Ім'я користувача бази даних"
  value = var.username
  sensitive = true
}

# Ідентифікатори ресурсів
output "db_instance_id" {
  description = "ID RDS інстансу (якщо використовується RDS)"
  value = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].id : null
  )
}

output "cluster_id" {
  description = "ID Aurora кластера (якщо використовується Aurora)"
  value = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].id : null
}

output "cluster_resource_id" {
  description = "Resource ID Aurora кластера (якщо використовується Aurora)"
  value = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].cluster_resource_id : null
}

output "cluster_members" {
  description = "Список членів Aurora кластера"
  value = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].cluster_members : []
}

# Мережеві ресурси
output "security_group_id" {
  description = "ID Security Group бази даних"
  value = aws_security_group.db.id
}

output "subnet_group_name" {
  description = "Назва DB Subnet Group"
  value = aws_db_subnet_group.main.name
}

# Parameter Groups
output "parameter_group_name" {
  description = "Назва Parameter Group"
  value = var.use_aurora ? (
    length(aws_rds_cluster_parameter_group.main) > 0 ? aws_rds_cluster_parameter_group.main[0].name : null
  ) : (
    length(aws_db_parameter_group.main) > 0 ? aws_db_parameter_group.main[0].name : null
  )
}

# Інформація про движок
output "engine" {
  description = "Движок бази даних"
  value = local.aurora_engine
}

output "engine_version" {
  description = "Версія движка бази даних"
  value = local.default_engine_version
}

# Статус та доступність
output "availability_zone" {
  description = "Зона доступності (для RDS)"
  value = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].availability_zone : null
  )
}

output "multi_az" {
  description = "Чи увімкнено Multi-AZ"
  value = var.use_aurora ? true : var.multi_az
}

# Моніторинг
output "monitoring_role_arn" {
  description = "ARN ролі для Enhanced Monitoring"
  value = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

# Підключення
output "connection_string" {
  description = "Рядок підключення до бази даних"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? 
    "postgresql://${var.username}:${var.password}@${aws_rds_cluster.main[0].endpoint}:${local.default_port}/${var.database_name}" : null
  ) : (
    length(aws_db_instance.main) > 0 ? 
    "${local.aurora_engine}://${var.username}:${var.password}@${aws_db_instance.main[0].endpoint}:${local.default_port}/${var.database_name}" : null
  )
  sensitive = true
}