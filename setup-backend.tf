# Файл для початкового налаштування S3 backend
# Використовуйте цей файл для створення S3 та DynamoDB ресурсів
# Після створення перенесіть конфігурацію в backend.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Модуль для створення S3 backend
module "s3_backend" {
  source = "./modules/s3-backend"
  
  # Основні параметри
  bucket_name          = var.backend_bucket_name
  dynamodb_table_name  = var.backend_dynamodb_table_name
  environment          = var.environment
  
  # S3 налаштування
  state_retention_days   = var.state_retention_days
  enable_access_logging  = var.enable_access_logging
  
  # DynamoDB налаштування
  dynamodb_billing_mode                    = var.dynamodb_billing_mode
  dynamodb_read_capacity                   = var.dynamodb_read_capacity
  dynamodb_write_capacity                  = var.dynamodb_write_capacity
  enable_point_in_time_recovery           = var.enable_point_in_time_recovery
  enable_dynamodb_autoscaling             = var.enable_dynamodb_autoscaling
  dynamodb_autoscaling_read_max_capacity  = var.dynamodb_autoscaling_read_max_capacity
  dynamodb_autoscaling_write_max_capacity = var.dynamodb_autoscaling_write_max_capacity
  dynamodb_autoscaling_target_value       = var.dynamodb_autoscaling_target_value
  
  # Моніторинг
  enable_cloudwatch_alarms = var.enable_cloudwatch_alarms
  sns_topic_arn           = var.sns_topic_arn
  
  # Теги
  tags = var.backend_tags
}

# Змінні для backend налаштування
variable "aws_region" {
  description = "AWS регіон"
  type        = string
  default     = "us-west-2"
}

variable "backend_bucket_name" {
  description = "Назва S3 бакета для Terraform state"
  type        = string
}

variable "backend_dynamodb_table_name" {
  description = "Назва DynamoDB таблиці для state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "environment" {
  description = "Середовище (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "state_retention_days" {
  description = "Кількість днів для зберігання старих версій стану"
  type        = number
  default     = 90
}

variable "enable_access_logging" {
  description = "Увімкнути логування доступу до S3"
  type        = bool
  default     = false
}

variable "dynamodb_billing_mode" {
  description = "Режим біллінгу для DynamoDB"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_read_capacity" {
  description = "Read capacity для DynamoDB (PROVISIONED режим)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Write capacity для DynamoDB (PROVISIONED режим)"
  type        = number
  default     = 5
}

variable "enable_point_in_time_recovery" {
  description = "Увімкнути Point-in-Time Recovery"
  type        = bool
  default     = true
}

variable "enable_dynamodb_autoscaling" {
  description = "Увімкнути автоскейлінг для DynamoDB"
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
  description = "Цільове значення утилізації для автоскейлінгу"
  type        = number
  default     = 70
}

variable "enable_cloudwatch_alarms" {
  description = "Увімкнути CloudWatch алерти"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "ARN SNS топіка для алертів"
  type        = string
  default     = ""
}

variable "backend_tags" {
  description = "Теги для backend ресурсів"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Purpose   = "terraform-backend"
  }
}

# Виводи
output "s3_bucket_name" {
  description = "Назва S3 бакета"
  value       = module.s3_backend.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "Назва DynamoDB таблиці"
  value       = module.s3_backend.dynamodb_table_name
}

output "backend_configuration" {
  description = "Конфігурація backend для копіювання"
  value       = module.s3_backend.backend_configuration
}