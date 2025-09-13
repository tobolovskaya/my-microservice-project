variable "use_aurora" {
  description = "Whether to use Aurora cluster (true) or regular RDS instance (false)"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database engine (mysql, postgres, aurora-mysql, aurora-postgresql)"
  type        = string
  default     = "postgres"
  
  validation {
    condition = contains([
      "mysql", "postgres", "mariadb",
      "aurora-mysql", "aurora-postgresql"
    ], var.engine)
    error_message = "Engine must be one of: mysql, postgres, mariadb, aurora-mysql, aurora-postgresql."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB (only for RDS, not Aurora)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (only for RDS)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Whether to encrypt storage"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "mydb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
  default     = null
}

variable "vpc_id" {
  description = "VPC ID where to create the database"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Name of final snapshot when deleting"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Whether to enable Performance Insights"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 0
}

variable "auto_minor_version_upgrade" {
  description = "Whether to enable auto minor version upgrade"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Whether to apply changes immediately"
  type        = bool
  default     = false
}

# Aurora specific variables
variable "aurora_cluster_instances" {
  description = "Number of Aurora cluster instances"
  type        = number
  default     = 2
}

variable "aurora_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.r5.large"
}

variable "aurora_backup_retention_period" {
  description = "Aurora backup retention period"
  type        = number
  default     = 7
}

variable "aurora_preferred_backup_window" {
  description = "Aurora preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "aurora_preferred_maintenance_window" {
  description = "Aurora preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# Parameter group variables
variable "parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = ""
}

variable "custom_parameters" {
  description = "Custom database parameters"
  type = map(object({
    value        = string
    apply_method = string
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "myproject"
}