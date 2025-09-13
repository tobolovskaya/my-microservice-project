# Aurora Cluster (when use_aurora = true)
resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  # Basic configuration
  cluster_identifier = "${var.project_name}-${var.environment}-aurora"
  engine             = local.actual_engine
  engine_version     = local.actual_engine_version

  # Database configuration
  database_name   = var.db_name
  master_username = var.username
  master_password = var.password
  port           = local.actual_port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # Backup configuration
  backup_retention_period = var.aurora_backup_retention_period
  preferred_backup_window = var.aurora_preferred_backup_window
  preferred_maintenance_window = var.aurora_preferred_maintenance_window

  # Storage configuration
  storage_encrypted = var.storage_encrypted
  kms_key_id       = var.kms_key_id != "" ? var.kms_key_id : null

  # Parameter groups
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora[0].name

  # Deletion protection
  deletion_protection      = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.project_name}-${var.environment}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  )

  # Maintenance
  apply_immediately = var.apply_immediately

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora-cluster"
      Type = "Aurora Cluster"
    }
  )

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db,
    aws_rds_cluster_parameter_group.aurora
  ]
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.use_aurora ? var.aurora_cluster_instances : 0

  identifier         = "${var.project_name}-${var.environment}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main[0].id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.main[0].engine
  engine_version     = aws_rds_cluster.main[0].engine_version

  # Parameter group
  db_parameter_group_name = aws_db_parameter_group.aurora_instance[0].name

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval
  monitoring_role_arn        = var.monitoring_interval > 0 ? aws_iam_role.aurora_enhanced_monitoring[0].arn : null

  # Maintenance
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately         = var.apply_immediately

  # Public accessibility
  publicly_accessible = var.publicly_accessible

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora-instance-${count.index + 1}"
      Type = "Aurora Instance"
      Role = count.index == 0 ? "Writer" : "Reader"
    }
  )

  depends_on = [aws_rds_cluster.main]
}

# IAM Role for Enhanced Monitoring (Aurora)
resource "aws_iam_role" "aurora_enhanced_monitoring" {
  count = var.use_aurora && var.monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-${var.environment}-aurora-monitoring-role"

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

resource "aws_iam_role_policy_attachment" "aurora_enhanced_monitoring" {
  count = var.use_aurora && var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.aurora_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}