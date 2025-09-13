# Головний файл для підключення модулів
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

# Модуль VPC
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  tags = var.common_tags
}

# Модуль RDS
module "rds" {
  source = "./modules/rds"
  
  # Основні параметри
  use_aurora        = var.use_aurora
  engine           = var.db_engine
  engine_version   = var.db_engine_version
  instance_class   = var.db_instance_class
  
  # Мережеві параметри
  vpc_id               = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [var.vpc_cidr]
  
  # Параметри БД
  database_name = var.database_name
  username     = var.db_username
  password     = var.db_password
  
  # Додаткові налаштування
  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  tags = var.common_tags
}

# Змінні
variable "aws_region" {
  description = "AWS регіон"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Список зон доступності"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR блоки для публічних підмереж"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR блоки для приватних підмереж"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "use_aurora" {
  description = "Використовувати Aurora кластер замість звичайної RDS"
  type        = bool
  default     = false
}

variable "db_engine" {
  description = "Движок бази даних"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Версія движка бази даних"
  type        = string
  default     = "15.4"
}

variable "db_instance_class" {
  description = "Клас інстансу бази даних"
  type        = string
  default     = "db.t3.micro"
}

variable "database_name" {
  description = "Назва бази даних"
  type        = string
  default     = "myapp"
}

variable "db_username" {
  description = "Ім'я користувача бази даних"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Пароль бази даних"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Увімкнути Multi-AZ розгортання"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Період зберігання бекапів (дні)"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Вікно для створення бекапів"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Вікно для обслуговування"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "common_tags" {
  description = "Загальні теги для всіх ресурсів"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-rds-module"
    ManagedBy   = "terraform"
  }
}