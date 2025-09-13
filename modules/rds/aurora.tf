# Створення Aurora кластера бази даних

# Aurora Cluster
resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  # Основні параметри
  cluster_identifier = "${var.tags.Project}-aurora-cluster"
  engine             = local.aurora_engine
  engine_version     = local.default_engine_version

  # База даних
  database_name   = var.database_name
  master_username = var.username
  master_password = var.password
  port           = local.default_port

  # Мережа та безпека
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # Параметри
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main[0].name

  # Бекапи та обслуговування
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.tags.Project}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Захист
  deletion_protection = var.deletion_protection
  copy_tags_to_snapshot = true

  # Шифрування
  storage_encrypted = var.storage_encrypted

  # Логи
  enabled_cloudwatch_logs_exports = local.logs_exports

  # Serverless v2 налаштування
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.aurora_serverless_v2 ? [1] : []
    content {
      max_capacity = var.aurora_serverless_v2_scaling.max_capacity
      min_capacity = var.aurora_serverless_v2_scaling.min_capacity
    }
  }

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-aurora-cluster"
  })

  lifecycle {
    ignore_changes = [
      master_password,
      final_snapshot_identifier
    ]
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db,
    aws_rds_cluster_parameter_group.main
  ]
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.use_aurora ? var.aurora_cluster_instances : 0

  identifier         = "${var.tags.Project}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.main[0].id
  instance_class     = var.aurora_serverless_v2 ? "db.serverless" : var.instance_class
  engine             = aws_rds_cluster.main[0].engine
  engine_version     = aws_rds_cluster.main[0].engine_version

  # Моніторинг
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  # Автоматичні оновлення
  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-aurora-instance-${count.index}"
  })

  depends_on = [aws_rds_cluster.main]
}