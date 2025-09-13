# Local values for common configurations
locals {
  # Determine the actual engine based on use_aurora flag
  actual_engine = var.use_aurora ? (
    var.engine == "mysql" || var.engine == "aurora-mysql" ? "aurora-mysql" : "aurora-postgresql"
  ) : var.engine

  # Default ports based on engine
  default_ports = {
    mysql             = 3306
    postgres          = 5432
    mariadb          = 3306
    aurora-mysql     = 3306
    aurora-postgresql = 5432
  }

  # Actual port to use
  actual_port = var.port != null ? var.port : local.default_ports[local.actual_engine]

  # Parameter group families
  parameter_group_families = {
    mysql             = "mysql8.0"
    postgres          = "postgres15"
    mariadb          = "mariadb10.6"
    aurora-mysql     = "aurora-mysql8.0"
    aurora-postgresql = "aurora-postgresql15"
  }

  # Actual parameter group family
  actual_parameter_group_family = var.parameter_group_family != "" ? var.parameter_group_family : local.parameter_group_families[local.actual_engine]

  # Default engine versions
  default_engine_versions = {
    mysql             = "8.0.35"
    postgres          = "15.4"
    mariadb          = "10.6.14"
    aurora-mysql     = "8.0.mysql_aurora.3.04.0"
    aurora-postgresql = "15.4"
  }

  # Actual engine version
  actual_engine_version = var.engine_version != "" ? var.engine_version : local.default_engine_versions[local.actual_engine]

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Engine      = local.actual_engine
    }
  )

  # Default parameters based on engine
  default_parameters = {
    mysql = {
      max_connections = {
        value        = "1000"
        apply_method = "pending-reboot"
      }
      innodb_buffer_pool_size = {
        value        = "{DBInstanceClassMemory*3/4}"
        apply_method = "pending-reboot"
      }
      slow_query_log = {
        value        = "1"
        apply_method = "immediate"
      }
    }
    postgres = {
      max_connections = {
        value        = "200"
        apply_method = "pending-reboot"
      }
      shared_preload_libraries = {
        value        = "pg_stat_statements"
        apply_method = "pending-reboot"
      }
      log_statement = {
        value        = "all"
        apply_method = "immediate"
      }
      work_mem = {
        value        = "4096"
        apply_method = "immediate"
      }
    }
    mariadb = {
      max_connections = {
        value        = "1000"
        apply_method = "pending-reboot"
      }
      innodb_buffer_pool_size = {
        value        = "{DBInstanceClassMemory*3/4}"
        apply_method = "pending-reboot"
      }
    }
    aurora-mysql = {
      max_connections = {
        value        = "1000"
        apply_method = "pending-reboot"
      }
      innodb_buffer_pool_size = {
        value        = "{DBInstanceClassMemory*3/4}"
        apply_method = "pending-reboot"
      }
    }
    aurora-postgresql = {
      max_connections = {
        value        = "200"
        apply_method = "pending-reboot"
      }
      shared_preload_libraries = {
        value        = "pg_stat_statements"
        apply_method = "pending-reboot"
      }
      log_statement = {
        value        = "all"
        apply_method = "immediate"
      }
      work_mem = {
        value        = "4096"
        apply_method = "immediate"
      }
    }
  }

  # Merge default and custom parameters
  final_parameters = merge(
    local.default_parameters[local.actual_engine],
    var.custom_parameters
  )
}

# DB Subnet Group (common for both RDS and Aurora)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-subnet-group"
    }
  )
}

# Security Group (common for both RDS and Aurora)
resource "aws_security_group" "db" {
  name_prefix = "${var.project_name}-${var.environment}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for ${var.use_aurora ? "Aurora cluster" : "RDS instance"}"

  # Ingress rules for CIDR blocks
  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = local.actual_port
      to_port     = local.actual_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
      description = "Database access from CIDR blocks"
    }
  }

  # Ingress rules for security groups
  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      from_port                = local.actual_port
      to_port                  = local.actual_port
      protocol                 = "tcp"
      source_security_group_id = ingress.value
      description              = "Database access from security group ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Parameter Group for RDS
resource "aws_db_parameter_group" "rds" {
  count = var.use_aurora ? 0 : 1

  family = local.actual_parameter_group_family
  name   = "${var.project_name}-${var.environment}-rds-params"

  dynamic "parameter" {
    for_each = local.final_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster Parameter Group for Aurora
resource "aws_rds_cluster_parameter_group" "aurora" {
  count = var.use_aurora ? 1 : 0

  family = local.actual_parameter_group_family
  name   = "${var.project_name}-${var.environment}-aurora-cluster-params"

  dynamic "parameter" {
    for_each = local.final_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora-cluster-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DB Parameter Group for Aurora instances
resource "aws_db_parameter_group" "aurora_instance" {
  count = var.use_aurora ? 1 : 0

  family = local.actual_parameter_group_family
  name   = "${var.project_name}-${var.environment}-aurora-instance-params"

  # Instance-specific parameters can be added here
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora-instance-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}