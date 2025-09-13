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

# Модуль EKS
module "eks" {
  source = "./modules/eks"
  
  # Основні параметри
  cluster_name       = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version
  
  # Мережеві параметри
  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  
  # Node Groups
  node_groups = var.node_groups
  
  # EBS CSI Driver
  enable_ebs_csi_driver = var.enable_ebs_csi_driver
  
  tags = var.common_tags
}

# Модуль ECR
module "ecr" {
  source = "./modules/ecr"
  
  # Основні параметри
  repository_name      = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  
  # Сканування
  scan_on_push             = var.ecr_scan_on_push
  enable_registry_scanning = var.ecr_enable_registry_scanning
  
  # Шифрування
  encryption_type = var.ecr_encryption_type
  kms_key        = var.ecr_kms_key
  
  # Політика життєвого циклу
  enable_lifecycle_policy = var.ecr_enable_lifecycle_policy
  max_image_count        = var.ecr_max_image_count
  untagged_image_days    = var.ecr_untagged_image_days
  
  # Міжакаунтний доступ
  enable_cross_account_access = var.ecr_enable_cross_account_access
  cross_account_arns         = var.ecr_cross_account_arns
  
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

# EKS змінні
variable "eks_cluster_name" {
  description = "Назва EKS кластера"
  type        = string
  default     = "my-eks-cluster"
}

variable "kubernetes_version" {
  description = "Версія Kubernetes"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Конфігурація node groups"
  type = list(object({
    name                         = string
    instance_types              = list(string)
    ami_type                    = string
    capacity_type               = string
    desired_size                = number
    max_size                    = number
    min_size                    = number
    max_unavailable_percentage  = number
    disk_size                   = number
    disk_type                   = string
    subnet_ids                  = list(string)
    labels                      = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    bootstrap_extra_args = string
  }))
  default = [
    {
      name                        = "main"
      instance_types             = ["t3.medium"]
      ami_type                   = "AL2_x86_64"
      capacity_type              = "ON_DEMAND"
      desired_size               = 2
      max_size                   = 4
      min_size                   = 1
      max_unavailable_percentage = 25
      disk_size                  = 50
      disk_type                  = "gp3"
      subnet_ids                 = []
      labels                     = {}
      taints                     = []
      bootstrap_extra_args       = ""
    }
  ]
}

variable "enable_ebs_csi_driver" {
  description = "Увімкнути AWS EBS CSI Driver"
  type        = bool
  default     = true
}

# ECR змінні
variable "ecr_repository_name" {
  description = "Назва ECR репозиторію"
  type        = string
  default     = "my-app"
}

variable "ecr_image_tag_mutability" {
  description = "Можливість змінювати теги образів"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Сканувати образи при завантаженні"
  type        = bool
  default     = true
}

variable "ecr_enable_registry_scanning" {
  description = "Увімкнути розширене сканування реєстру"
  type        = bool
  default     = false
}

variable "ecr_encryption_type" {
  description = "Тип шифрування ECR"
  type        = string
  default     = "AES256"
}

variable "ecr_kms_key" {
  description = "ARN KMS ключа для шифрування ECR"
  type        = string
  default     = null
}

variable "ecr_enable_lifecycle_policy" {
  description = "Увімкнути політику життєвого циклу ECR"
  type        = bool
  default     = true
}

variable "ecr_max_image_count" {
  description = "Максимальна кількість образів для зберігання"
  type        = number
  default     = 10
}

variable "ecr_untagged_image_days" {
  description = "Кількість днів для зберігання образів без тегів"
  type        = number
  default     = 1
}

variable "ecr_enable_cross_account_access" {
  description = "Увімкнути міжакаунтний доступ до ECR"
  type        = bool
  default     = false
}

variable "ecr_cross_account_arns" {
  description = "ARN акаунтів для міжакаунтного доступу"
  type        = list(string)
  default     = []
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