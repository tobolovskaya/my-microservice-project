# Common outputs
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}

output "port" {
  description = "Database port"
  value       = local.actual_port
}

output "engine" {
  description = "Database engine"
  value       = local.actual_engine
}

output "engine_version" {
  description = "Database engine version"
  value       = local.actual_engine_version
}

# RDS specific outputs
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = var.use_aurora ? null : aws_db_instance.main[0].id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = var.use_aurora ? null : aws_db_instance.main[0].arn
}

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = var.use_aurora ? null : aws_db_instance.main[0].endpoint
}

output "rds_instance_hosted_zone_id" {
  description = "RDS instance hosted zone ID"
  value       = var.use_aurora ? null : aws_db_instance.main[0].hosted_zone_id
}

output "rds_instance_resource_id" {
  description = "RDS instance resource ID"
  value       = var.use_aurora ? null : aws_db_instance.main[0].resource_id
}

output "rds_instance_status" {
  description = "RDS instance status"
  value       = var.use_aurora ? null : aws_db_instance.main[0].status
}

output "rds_instance_address" {
  description = "RDS instance address"
  value       = var.use_aurora ? null : aws_db_instance.main[0].address
}

# Aurora specific outputs
output "aurora_cluster_id" {
  description = "Aurora cluster ID"
  value       = var.use_aurora ? aws_rds_cluster.main[0].id : null
}

output "aurora_cluster_arn" {
  description = "Aurora cluster ARN"
  value       = var.use_aurora ? aws_rds_cluster.main[0].arn : null
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = var.use_aurora ? aws_rds_cluster.main[0].endpoint : null
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = var.use_aurora ? aws_rds_cluster.main[0].reader_endpoint : null
}

output "aurora_cluster_hosted_zone_id" {
  description = "Aurora cluster hosted zone ID"
  value       = var.use_aurora ? aws_rds_cluster.main[0].hosted_zone_id : null
}

output "aurora_cluster_resource_id" {
  description = "Aurora cluster resource ID"
  value       = var.use_aurora ? aws_rds_cluster.main[0].cluster_resource_id : null
}

output "aurora_cluster_members" {
  description = "List of Aurora cluster members"
  value       = var.use_aurora ? aws_rds_cluster.main[0].cluster_members : null
}

output "aurora_instance_ids" {
  description = "List of Aurora instance IDs"
  value       = var.use_aurora ? aws_rds_cluster_instance.cluster_instances[*].id : null
}

output "aurora_instance_endpoints" {
  description = "List of Aurora instance endpoints"
  value       = var.use_aurora ? aws_rds_cluster_instance.cluster_instances[*].endpoint : null
}

# Connection information
output "connection_info" {
  description = "Database connection information"
  value = {
    endpoint = var.use_aurora ? aws_rds_cluster.main[0].endpoint : aws_db_instance.main[0].endpoint
    port     = local.actual_port
    database = var.db_name
    username = var.username
    engine   = local.actual_engine
  }
  sensitive = false
}

# Parameter group outputs
output "parameter_group_name" {
  description = "Name of the parameter group"
  value = var.use_aurora ? (
    length(aws_rds_cluster_parameter_group.aurora) > 0 ? aws_rds_cluster_parameter_group.aurora[0].name : null
  ) : (
    length(aws_db_parameter_group.rds) > 0 ? aws_db_parameter_group.rds[0].name : null
  )
}

output "parameter_group_arn" {
  description = "ARN of the parameter group"
  value = var.use_aurora ? (
    length(aws_rds_cluster_parameter_group.aurora) > 0 ? aws_rds_cluster_parameter_group.aurora[0].arn : null
  ) : (
    length(aws_db_parameter_group.rds) > 0 ? aws_db_parameter_group.rds[0].arn : null
  )
}

# Monitoring outputs
output "enhanced_monitoring_role_arn" {
  description = "ARN of the enhanced monitoring IAM role"
  value = var.use_aurora ? (
    var.monitoring_interval > 0 ? aws_iam_role.aurora_enhanced_monitoring[0].arn : null
  ) : (
    var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  )
}

# Summary output
output "database_summary" {
  description = "Summary of the created database resources"
  value = {
    type                = var.use_aurora ? "Aurora Cluster" : "RDS Instance"
    engine              = local.actual_engine
    engine_version      = local.actual_engine_version
    instance_class      = var.use_aurora ? var.aurora_instance_class : var.instance_class
    instance_count      = var.use_aurora ? var.aurora_cluster_instances : 1
    multi_az           = var.use_aurora ? true : var.multi_az
    storage_encrypted   = var.storage_encrypted
    backup_retention    = var.use_aurora ? var.aurora_backup_retention_period : var.backup_retention_period
    deletion_protection = var.deletion_protection
    publicly_accessible = var.publicly_accessible
  }
}