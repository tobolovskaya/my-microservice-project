# Змінні для RDS модуля

# Основні параметри
variable "use_aurora" {
  description = "Використовувати Aurora кластер замість звичайної RDS інстансу"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Движок бази даних (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"
  
  validation {
    condition = contains([
      "postgres", "mysql", "mariadb",
      "aurora-postgresql", "aurora-mysql"
    ], var.engine)
    error_message = "Engine повинен бути одним з: postgres, mysql, mariadb, aurora-postgresql, aurora-mysql."
  }
}

variable "engine_version" {
  description = "Версія движка бази даних"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "Клас інстансу бази даних"
  type        = string
  default     = "db.t3.micro"
}

# Мережеві параметри
variable "vpc_id" {
  description = "ID VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Список ID підмереж для DB subnet group"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Потрібно мінімум 2 підмережі для DB subnet group."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR блоки, яким дозволено підключення до БД"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "Security groups, яким дозволено підключення до БД"
  type        = list(string)
  default     = []
}

# Параметри бази даних
variable "database_name" {
  description = "Назва бази даних"
  type        = string
  default     = "myapp"
}

variable "username" {
  description = "Головний користувач бази даних"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Пароль головного користувача"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Порт бази даних (автоматично визначається за движком, якщо не вказано)"
  type        = number
  default     = null
}

# Налаштування продуктивності та доступності
variable "allocated_storage" {
  description = "Розмір сховища в ГБ (тільки для RDS)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Максимальний розмір сховища для автоскейлінгу (тільки для RDS)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Тип сховища (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Шифрувати сховище"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Увімкнути Multi-AZ розгортання"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Чи повинна БД бути доступною з інтернету"
  type        = bool
  default     = false
}

# Налаштування бекапів та обслуговування
variable "backup_retention_period" {
  description = "Період зберігання бекапів в днях"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Період зберігання бекапів повинен бути від 0 до 35 днів."
  }
}

variable "backup_window" {
  description = "Вікно для створення бекапів (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Вікно для обслуговування (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Пропустити фінальний snapshot при видаленні"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Захист від видалення"
  type        = bool
  default     = true
}

# Моніторинг та логування
variable "monitoring_interval" {
  description = "Інтервал моніторингу в секундах (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60
  
  validation {
    condition = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Інтервал моніторингу повинен бути одним з: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Увімкнути Performance Insights"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Список типів логів для експорту в CloudWatch"
  type        = list(string)
  default     = []
}

# Aurora специфічні параметри
variable "aurora_cluster_instances" {
  description = "Кількість інстансів в Aurora кластері"
  type        = number
  default     = 2
  
  validation {
    condition     = var.aurora_cluster_instances >= 1 && var.aurora_cluster_instances <= 15
    error_message = "Кількість інстансів повинна бути від 1 до 15."
  }
}

variable "aurora_serverless_v2" {
  description = "Використовувати Aurora Serverless v2"
  type        = bool
  default     = false
}

variable "aurora_serverless_v2_scaling" {
  description = "Налаштування масштабування для Aurora Serverless v2"
  type = object({
    max_capacity = number
    min_capacity = number
  })
  default = {
    max_capacity = 1
    min_capacity = 0.5
  }
}

# Кастомні параметри БД
variable "custom_db_parameters" {
  description = "Кастомні параметри для parameter group"
  type = map(object({
    value        = string
    apply_method = string
  }))
  default = {}
}

# Теги
variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default     = {}
}