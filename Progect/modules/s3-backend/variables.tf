# Змінні для модуля s3-backend

# Основні параметри
variable "bucket_name" {
  description = "Назва S3 бакета для зберігання стану Terraform"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Назва бакета повинна містити тільки малі літери, цифри та дефіси, починатися та закінчуватися літерою або цифрою."
  }
}

variable "dynamodb_table_name" {
  description = "Назва DynamoDB таблиці для блокування стану"
  type        = string
  default     = "terraform-state-lock"
}

variable "environment" {
  description = "Середовище (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment повинен бути одним з: dev, staging, prod."
  }
}

# S3 налаштування
variable "state_retention_days" {
  description = "Кількість днів для зберігання старих версій стану"
  type        = number
  default     = 90
  
  validation {
    condition     = var.state_retention_days >= 1 && var.state_retention_days <= 365
    error_message = "Період зберігання повинен бути від 1 до 365 днів."
  }
}

variable "enable_access_logging" {
  description = "Увімкнути логування доступу до S3 бакета"
  type        = bool
  default     = false
}

# DynamoDB налаштування
variable "dynamodb_billing_mode" {
  description = "Режим біллінгу для DynamoDB (PAY_PER_REQUEST або PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
  
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode повинен бути PAY_PER_REQUEST або PROVISIONED."
  }
}

variable "dynamodb_read_capacity" {
  description = "Read capacity units для DynamoDB (тільки для PROVISIONED режиму)"
  type        = number
  default     = 5
  
  validation {
    condition     = var.dynamodb_read_capacity >= 1
    error_message = "Read capacity повинен бути мінімум 1."
  }
}

variable "dynamodb_write_capacity" {
  description = "Write capacity units для DynamoDB (тільки для PROVISIONED режиму)"
  type        = number
  default     = 5
  
  validation {
    condition     = var.dynamodb_write_capacity >= 1
    error_message = "Write capacity повинен бути мінімум 1."
  }
}

variable "enable_point_in_time_recovery" {
  description = "Увімкнути Point-in-Time Recovery для DynamoDB"
  type        = bool
  default     = true
}

# Auto Scaling налаштування
variable "enable_dynamodb_autoscaling" {
  description = "Увімкнути автоскейлінг для DynamoDB (тільки для PROVISIONED режиму)"
  type        = bool
  default     = true
}

variable "dynamodb_autoscaling_read_max_capacity" {
  description = "Максимальна read capacity для автоскейлінгу"
  type        = number
  default     = 100
}

variable "dynamodb_autoscaling_write_max_capacity" {
  description = "Максимальна write capacity для автоскейлінгу"
  type        = number
  default     = 100
}

variable "dynamodb_autoscaling_target_value" {
  description = "Цільове значення утилізації для автоскейлінгу (%)"
  type        = number
  default     = 70
  
  validation {
    condition     = var.dynamodb_autoscaling_target_value >= 10 && var.dynamodb_autoscaling_target_value <= 90
    error_message = "Цільове значення повинно бути від 10% до 90%."
  }
}

# Моніторинг
variable "enable_cloudwatch_alarms" {
  description = "Увімкнути CloudWatch алерти"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "ARN SNS топіка для надсилання алертів"
  type        = string
  default     = ""
}

# Теги
variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "s3-backend"
  }
}