# Змінні для Jenkins модуля

# Основні параметри
variable "release_name" {
  description = "Назва Helm release для Jenkins"
  type        = string
  default     = "jenkins"
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.release_name))
    error_message = "Release name повинна містити тільки малі літери, цифри та дефіси."
  }
}

variable "namespace" {
  description = "Kubernetes namespace для Jenkins"
  type        = string
  default     = "jenkins"
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace повинен містити тільки малі літери, цифри та дефіси."
  }
}

# Helm налаштування
variable "helm_repository" {
  description = "Helm repository URL для Jenkins chart"
  type        = string
  default     = "https://charts.jenkins.io"
}

variable "helm_chart" {
  description = "Назва Helm chart для Jenkins"
  type        = string
  default     = "jenkins"
}

variable "helm_chart_version" {
  description = "Версія Helm chart для Jenkins"
  type        = string
  default     = "4.8.3"
}

variable "helm_timeout" {
  description = "Timeout для Helm операцій (секунди)"
  type        = number
  default     = 600
  
  validation {
    condition     = var.helm_timeout >= 300 && var.helm_timeout <= 1800
    error_message = "Helm timeout повинен бути від 300 до 1800 секунд."
  }
}

# Jenkins конфігурація
variable "admin_user" {
  description = "Ім'я адміністратора Jenkins"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Пароль адміністратора Jenkins"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Пароль адміністратора повинен містити мінімум 8 символів."
  }
}

variable "jenkins_config_files" {
  description = "Додаткові конфігураційні файли для Jenkins"
  type        = map(string)
  default     = {}
}

variable "additional_values" {
  description = "Додаткові Helm values у YAML форматі"
  type        = string
  default     = ""
}

# Ресурси
variable "resources" {
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

# Сховище
variable "persistence_enabled" {
  description = "Увімкнути persistent storage для Jenkins"
  type        = bool
  default     = true
}

variable "storage_size" {
  description = "Розмір сховища для Jenkins home"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class для Jenkins PVC"
  type        = string
  default     = "gp3"
}

variable "create_pvc" {
  description = "Створити PVC для Jenkins (якщо false, використовується динамічне створення)"
  type        = bool
  default     = true
}

# Мережеві налаштування
variable "service_type" {
  description = "Тип Kubernetes service для Jenkins"
  type        = string
  default     = "ClusterIP"
  
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type повинен бути ClusterIP, NodePort або LoadBalancer."
  }
}

variable "create_load_balancer_service" {
  description = "Створити додатковий LoadBalancer service"
  type        = bool
  default     = false
}

variable "load_balancer_annotations" {
  description = "Анотації для LoadBalancer service"
  type        = map(string)
  default = {
    "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
  }
}

variable "load_balancer_source_ranges" {
  description = "CIDR блоки для доступу до LoadBalancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Ingress налаштування
variable "ingress_enabled" {
  description = "Увімкнути Ingress для Jenkins"
  type        = bool
  default     = true
}

variable "create_custom_ingress" {
  description = "Створити кастомний Ingress ресурс"
  type        = bool
  default     = false
}

variable "ingress_hostname" {
  description = "Hostname для Jenkins Ingress"
  type        = string
  default     = "jenkins.local"
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_annotations" {
  description = "Додаткові анотації для Ingress"
  type        = map(string)
  default = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }
}

variable "ingress_tls_enabled" {
  description = "Увімкнути TLS для Ingress"
  type        = bool
  default     = true
}

variable "ingress_tls_secret_name" {
  description = "Назва secret для TLS сертифіката"
  type        = string
  default     = "jenkins-tls"
}

# Plugins
variable "install_plugins" {
  description = "Список плагінів для встановлення в Jenkins"
  type        = list(string)
  default = [
    "kubernetes:4029.v5712230ccb_f8",
    "workflow-aggregator:596.v8c21c963d92d",
    "git:5.0.0",
    "configuration-as-code:1670.v564dc8b_982d0",
    "blueocean:1.27.2",
    "pipeline-stage-view:2.25",
    "docker-workflow:563.vd5d2e5c4007f",
    "aws-credentials:191.vcb_f183ce58b_9",
    "pipeline-aws:1.43",
    "amazon-ecr:1.7.3",
    "slack:631.v40deea_40323b",
    "github:1.37.3.1",
    "pipeline-github-lib:42.v0739460cda_c4",
    "sonar:2.15",
    "build-timeout:1.30",
    "timestamper:1.25",
    "ws-cleanup:0.45",
    "ant:475.vf34069fef73c",
    "gradle:2.8.2",
    "nodejs:1.6.1",
    "maven-plugin:3.22"
  ]
}

# AWS інтеграція
variable "aws_region" {
  description = "AWS регіон для інтеграції"
  type        = string
  default     = ""
}

variable "ecr_registry_url" {
  description = "URL ECR registry для Docker builds"
  type        = string
  default     = ""
}

# Auto Scaling
variable "enable_hpa" {
  description = "Увімкнути HorizontalPodAutoscaler"
  type        = bool
  default     = false
}

variable "hpa_min_replicas" {
  description = "Мінімальна кількість реплік для HPA"
  type        = number
  default     = 1
  
  validation {
    condition     = var.hpa_min_replicas >= 1
    error_message = "Мінімальна кількість реплік повинна бути мінімум 1."
  }
}

variable "hpa_max_replicas" {
  description = "Максимальна кількість реплік для HPA"
  type        = number
  default     = 3
  
  validation {
    condition     = var.hpa_max_replicas >= 1
    error_message = "Максимальна кількість реплік повинна бути мінімум 1."
  }
}

variable "hpa_target_cpu_utilization" {
  description = "Цільова утилізація CPU для HPA (%)"
  type        = number
  default     = 70
  
  validation {
    condition     = var.hpa_target_cpu_utilization >= 1 && var.hpa_target_cpu_utilization <= 100
    error_message = "Цільова утилізація CPU повинна бути від 1% до 100%."
  }
}

variable "hpa_target_memory_utilization" {
  description = "Цільова утилізація пам'яті для HPA (%)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.hpa_target_memory_utilization >= 1 && var.hpa_target_memory_utilization <= 100
    error_message = "Цільова утилізація пам'яті повинна бути від 1% до 100%."
  }
}

# Безпека
variable "security_context_enabled" {
  description = "Увімкнути security context для Jenkins"
  type        = bool
  default     = true
}

variable "pod_security_policy_enabled" {
  description = "Увімкнути Pod Security Policy"
  type        = bool
  default     = false
}

variable "network_policy_enabled" {
  description = "Увімкнути Network Policy для Jenkins"
  type        = bool
  default     = false
}

# Моніторинг
variable "enable_prometheus_monitoring" {
  description = "Увімкнути Prometheus моніторинг"
  type        = bool
  default     = true
}

variable "prometheus_scrape_interval" {
  description = "Інтервал збору метрик Prometheus"
  type        = string
  default     = "30s"
}

# Backup
variable "enable_backup" {
  description = "Увімкнути автоматичне резервне копіювання"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron розклад для резервного копіювання"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_retention_days" {
  description = "Кількість днів зберігання резервних копій"
  type        = number
  default     = 30
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Період зберігання резервних копій повинен бути від 1 до 365 днів."
  }
}

# Теги
variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "jenkins"
  }
}

# Додаткові налаштування
variable "timezone" {
  description = "Часовий пояс для Jenkins"
  type        = string
  default     = "UTC"
}

variable "java_opts" {
  description = "Додаткові Java опції для Jenkins"
  type        = string
  default     = "-Xmx2g -Xms1g"
}

variable "jenkins_opts" {
  description = "Додаткові Jenkins опції"
  type        = string
  default     = ""
}

variable "enable_csrf_protection" {
  description = "Увімкнути CSRF захист"
  type        = bool
  default     = true
}

variable "enable_script_security" {
  description = "Увімкнути script security"
  type        = bool
  default     = true
}

variable "agent_connection_timeout" {
  description = "Timeout для підключення агентів (секунди)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.agent_connection_timeout >= 30 && var.agent_connection_timeout <= 300
    error_message = "Timeout підключення агентів повинен бути від 30 до 300 секунд."
  }
}