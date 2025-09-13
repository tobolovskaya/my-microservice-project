# Створення звичайної RDS бази даних

resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  # Основні параметри
  identifier     = "${var.tags.Project}-db"
  engine         = local.aurora_engine
  engine_version = local.default_engine_version
  instance_class = var.instance_class

  # База даних
  db_name  = var.database_name
  username = var.username
  password = var.password
  port     = local.default_port

  # Сховище
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Мережа та безпека
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = var.publicly_accessible

  # Доступність
  multi_az               = var.multi_az
  availability_zone      = var.multi_az ? null : data.aws_availability_zones.available.names[0]

  # Параметри
  parameter_group_name = aws_db_parameter_group.main[0].name

  # Бекапи та обслуговування
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.tags.Project}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Захист
  deletion_protection = var.deletion_protection
  copy_tags_to_snapshot = true

  # Моніторинг
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  # Логи
  enabled_cloudwatch_logs_exports = local.logs_exports

  # Автоматичні оновлення
  auto_minor_version_upgrade = true
  allow_major_version_upgrade = false

  tags = merge(var.tags, {
    Name = "${var.tags.Project}-database"
  })

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db,
    aws_db_parameter_group.main
  ]
}

# Дані про доступні зони
data "aws_availability_zones" "available" {
  state = "available"
}