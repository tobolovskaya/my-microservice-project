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

# Провайдери для Jenkins (потрібні для Helm та Kubernetes)
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# Модуль Jenkins
module "jenkins" {
  source = "./modules/jenkins"
  
  # Основні параметри
  release_name = var.jenkins_release_name
  namespace    = var.jenkins_namespace
  
  # Helm налаштування
  helm_chart_version = var.jenkins_helm_chart_version
  helm_timeout      = var.jenkins_helm_timeout
  
  # Jenkins конфігурація
  admin_user     = var.jenkins_admin_user
  admin_password = var.jenkins_admin_password
  
  # Ресурси
  resources = var.jenkins_resources
  
  # Сховище
  persistence_enabled = var.jenkins_persistence_enabled
  storage_size       = var.jenkins_storage_size
  storage_class      = var.jenkins_storage_class
  create_pvc         = var.jenkins_create_pvc
  
  # Мережеві налаштування
  service_type                    = var.jenkins_service_type
  create_load_balancer_service    = var.jenkins_create_load_balancer_service
  load_balancer_annotations       = var.jenkins_load_balancer_annotations
  load_balancer_source_ranges     = var.jenkins_load_balancer_source_ranges
  
  # Ingress
  ingress_enabled        = var.jenkins_ingress_enabled
  create_custom_ingress  = var.jenkins_create_custom_ingress
  ingress_hostname       = var.jenkins_ingress_hostname
  ingress_class_name     = var.jenkins_ingress_class_name
  ingress_annotations    = var.jenkins_ingress_annotations
  ingress_tls_enabled    = var.jenkins_ingress_tls_enabled
  ingress_tls_secret_name = var.jenkins_ingress_tls_secret_name
  
  # Plugins
  install_plugins = var.jenkins_install_plugins
  
  # AWS інтеграція
  aws_region        = var.aws_region
  ecr_registry_url  = module.ecr.repository_url
  
  # Auto Scaling
  enable_hpa                      = var.jenkins_enable_hpa
  hpa_min_replicas               = var.jenkins_hpa_min_replicas
  hpa_max_replicas               = var.jenkins_hpa_max_replicas
  hpa_target_cpu_utilization     = var.jenkins_hpa_target_cpu_utilization
  hpa_target_memory_utilization  = var.jenkins_hpa_target_memory_utilization
  
  # Моніторинг
  enable_prometheus_monitoring = var.jenkins_enable_prometheus_monitoring
  prometheus_scrape_interval   = var.jenkins_prometheus_scrape_interval
  
  # Backup
  enable_backup           = var.jenkins_enable_backup
  backup_schedule         = var.jenkins_backup_schedule
  backup_retention_days   = var.jenkins_backup_retention_days
  
  # Додаткові налаштування
  timezone                    = var.jenkins_timezone
  java_opts                   = var.jenkins_java_opts
  jenkins_opts                = var.jenkins_jenkins_opts
  enable_csrf_protection      = var.jenkins_enable_csrf_protection
  enable_script_security      = var.jenkins_enable_script_security
  agent_connection_timeout    = var.jenkins_agent_connection_timeout
  
  tags = var.common_tags
  
  depends_on = [
    module.eks,
    module.ecr
  ]
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

# Jenkins змінні
variable "jenkins_release_name" {
  description = "Назва Helm release для Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_namespace" {
  description = "Kubernetes namespace для Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_helm_chart_version" {
  description = "Версія Helm chart для Jenkins"
  type        = string
  default     = "4.8.3"
}

variable "jenkins_helm_timeout" {
  description = "Timeout для Helm операцій"
  type        = number
  default     = 600
}

variable "jenkins_admin_user" {
  description = "Ім'я адміністратора Jenkins"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins"
  type        = string
  sensitive   = true
}

variable "jenkins_resources" {
  description = "Ресурси для Jenkins controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2"
      memory = "4Gi"
    }
  }
}

variable "jenkins_persistence_enabled" {
  description = "Увімкнути persistent storage для Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_storage_size" {
  description = "Розмір сховища для Jenkins"
  type        = string
  default     = "20Gi"
}

variable "jenkins_storage_class" {
  description = "Storage class для Jenkins"
  type        = string
  default     = "gp3"
}

variable "jenkins_create_pvc" {
  description = "Створити PVC для Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_service_type" {
  description = "Тип Kubernetes service для Jenkins"
  type        = string
  default     = "ClusterIP"
}

variable "jenkins_create_load_balancer_service" {
  description = "Створити LoadBalancer service"
  type        = bool
  default     = false
}

variable "jenkins_load_balancer_annotations" {
  description = "Анотації для LoadBalancer service"
  type        = map(string)
  default = {
    "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
  }
}

variable "jenkins_load_balancer_source_ranges" {
  description = "CIDR блоки для LoadBalancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "jenkins_ingress_enabled" {
  description = "Увімкнути Ingress для Jenkins"
  type        = bool
  default     = true
}

variable "jenkins_create_custom_ingress" {
  description = "Створити кастомний Ingress"
  type        = bool
  default     = false
}

variable "jenkins_ingress_hostname" {
  description = "Hostname для Jenkins Ingress"
  type        = string
  default     = "jenkins.local"
}

variable "jenkins_ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "jenkins_ingress_annotations" {
  description = "Анотації для Ingress"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}

variable "jenkins_ingress_tls_enabled" {
  description = "Увімкнути TLS для Ingress"
  type        = bool
  default     = true
}

variable "jenkins_ingress_tls_secret_name" {
  description = "Назва TLS secret"
  type        = string
  default     = "jenkins-tls"
}

variable "jenkins_install_plugins" {
  description = "Список плагінів для Jenkins"
  type        = list(string)
  default = [
    "kubernetes:4029.v5712230ccb_f8",
    "workflow-aggregator:596.v8c21c963d92d",
    "git:5.0.0",
    "configuration-as-code:1670.v564dc8b_982d0",
    "blueocean:1.27.2",
    "docker-workflow:563.vd5d2e5c4007f",
    "aws-credentials:191.vcb_f183ce58b_9",
    "amazon-ecr:1.7.3"
  ]
}

variable "jenkins_enable_hpa" {
  description = "Увімкнути HorizontalPodAutoscaler"
  type        = bool
  default     = false
}

variable "jenkins_hpa_min_replicas" {
  description = "Мінімальна кількість реплік HPA"
  type        = number
  default     = 1
}

variable "jenkins_hpa_max_replicas" {
  description = "Максимальна кількість реплік HPA"
  type        = number
  default     = 3
}

variable "jenkins_hpa_target_cpu_utilization" {
  description = "Цільова утилізація CPU для HPA"
  type        = number
  default     = 70
}

variable "jenkins_hpa_target_memory_utilization" {
  description = "Цільова утилізація пам'яті для HPA"
  type        = number
  default     = 80
}

variable "jenkins_enable_prometheus_monitoring" {
  description = "Увімкнути Prometheus моніторинг"
  type        = bool
  default     = true
}

variable "jenkins_prometheus_scrape_interval" {
  description = "Інтервал збору метрик Prometheus"
  type        = string
  default     = "30s"
}

variable "jenkins_enable_backup" {
  description = "Увімкнути автоматичне резервне копіювання"
  type        = bool
  default     = false
}

variable "jenkins_backup_schedule" {
  description = "Cron розклад для резервного копіювання"
  type        = string
  default     = "0 2 * * *"
}

variable "jenkins_backup_retention_days" {
  description = "Кількість днів зберігання резервних копій"
  type        = number
  default     = 30
}

variable "jenkins_timezone" {
  description = "Часовий пояс для Jenkins"
  type        = string
  default     = "UTC"
}

variable "jenkins_java_opts" {
  description = "Java опції для Jenkins"
  type        = string
  default     = "-Xmx2g -Xms1g"
}

variable "jenkins_jenkins_opts" {
  description = "Jenkins опції"
  type        = string
  default     = ""
}

variable "jenkins_enable_csrf_protection" {
  description = "Увімкнути CSRF захист"
  type        = bool
  default     = true
}

variable "jenkins_enable_script_security" {
  description = "Увімкнути script security"
  type        = bool
  default     = true
}

variable "jenkins_agent_connection_timeout" {
  description = "Timeout для підключення агентів"
  type        = number
  default     = 100
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