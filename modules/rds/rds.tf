# Regular RDS Instance (when use_aurora = false)
resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  # Basic configuration
  identifier     = "${var.project_name}-${var.environment}-rds"
  engine         = local.actual_engine
  engine_version = local.actual_engine_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id           = var.kms_key_id != "" ? var.kms_key_id : null

  # Database configuration
  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = local.actual_port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = var.publicly_accessible

  # High availability
  multi_az = var.multi_az

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # Parameter group
  parameter_group_name = aws_db_parameter_group.rds[0].name

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval
  monitoring_role_arn        = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Maintenance
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately         = var.apply_immediately

  # Deletion protection
  deletion_protection      = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  )

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-rds"
      Type = "RDS Instance"
    }
  )

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db,
    aws_db_parameter_group.rds
  ]
}

# IAM Role for Enhanced Monitoring (RDS)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.use_aurora ? 0 : (var.monitoring_interval > 0 ? 1 : 0)

  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.use_aurora ? 0 : (var.monitoring_interval > 0 ? 1 : 0)

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}