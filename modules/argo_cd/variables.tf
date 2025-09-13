# Змінні для Argo CD модуля

# Основні параметри
variable "release_name" {
  description = "Назва Helm release для Argo CD"
  type        = string
  default     = "argocd"
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.release_name))
    error_message = "Release name повинна містити тільки малі літери, цифри та дефіси."
  }
}

variable "namespace" {
  description = "Kubernetes namespace для Argo CD"
  type        = string
  default     = "argocd"
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace повинен містити тільки малі літери, цифри та дефіси."
  }
}

# Helm налаштування
variable "helm_repository" {
  description = "Helm repository URL для Argo CD chart"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "helm_chart" {
  description = "Назва Helm chart для Argo CD"
  type        = string
  default     = "argo-cd"
}

variable "helm_chart_version" {
  description = "Версія Helm chart для Argo CD"
  type        = string
  default     = "5.51.6"
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

# Argo CD конфігурація
variable "admin_password" {
  description = "Пароль адміністратора Argo CD"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Пароль адміністратора повинен містити мінімум 8 символів."
  }
}

variable "argocd_config_files" {
  description = "Додаткові конфігураційні файли для Argo CD"
  type        = map(string)
  default     = {}
}

variable "additional_values" {
  description = "Додаткові Helm values у YAML форматі"
  type        = string
  default     = ""
}

# Ресурси для Controller
variable "controller_resources" {
  description = "Ресурси для Argo CD Application Controller"
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
      cpu    = "250m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "500m"
      memory = "2Gi"
    }
  }
}

# Ресурси для Server
variable "server_resources" {
  description = "Ресурси для Argo CD Server"
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
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

# Ресурси для Repo Server
variable "repo_server_resources" {
  description = "Ресурси для Argo CD Repo Server"
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
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
  }
}

# High Availability
variable "enable_ha" {
  description = "Увімкнути High Availability режим"
  type        = bool
  default     = false
}

variable "controller_replicas" {
  description = "Кількість реплік Application Controller (HA режим)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.controller_replicas >= 1 && var.controller_replicas <= 5
    error_message = "Кількість реплік Controller повинна бути від 1 до 5."
  }
}

variable "server_replicas" {
  description = "Кількість реплік Server (HA режим)"
  type        = number
  default     = 2
  
  validation {
    condition     = var.server_replicas >= 1 && var.server_replicas <= 10
    error_message = "Кількість реплік Server повинна бути від 1 до 10."
  }
}

variable "repo_server_replicas" {
  description = "Кількість реплік Repo Server (HA режим)"
  type        = number
  default     = 2
  
  validation {
    condition     = var.repo_server_replicas >= 1 && var.repo_server_replicas <= 10
    error_message = "Кількість реплік Repo Server повинна бути від 1 до 10."
  }
}

# Мережеві налаштування
variable "service_type" {
  description = "Тип Kubernetes service для Argo CD"
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
  description = "Увімкнути Ingress для Argo CD"
  type        = bool
  default     = true
}

variable "create_custom_ingress" {
  description = "Створити кастомний Ingress ресурс"
  type        = bool
  default     = false
}

variable "ingress_hostname" {
  description = "Hostname для Argo CD Ingress"
  type        = string
  default     = "argocd.local"
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
  default     = "argocd-tls"
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
  default     = 2
  
  validation {
    condition     = var.hpa_min_replicas >= 1
    error_message = "Мінімальна кількість реплік повинна бути мінімум 1."
  }
}

variable "hpa_max_replicas" {
  description = "Максимальна кількість реплік для HPA"
  type        = number
  default     = 5
  
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

# Функціональність
variable "enable_metrics" {
  description = "Увімкнути Prometheus метрики"
  type        = bool
  default     = true
}

variable "enable_notifications" {
  description = "Увімкнути Argo CD Notifications"
  type        = bool
  default     = true
}

variable "enable_applicationset" {
  description = "Увімкнути ApplicationSet Controller"
  type        = bool
  default     = true
}

variable "enable_dex" {
  description = "Увімкнути Dex для OIDC аутентифікації"
  type        = bool
  default     = false
}

# Git Repository налаштування
variable "git_repositories" {
  description = "Список Git репозиторіїв для Argo CD"
  type = list(object({
    url      = string
    name     = string
    username = optional(string)
    password = optional(string)
    ssh_key  = optional(string)
  }))
  default = []
}

# Demo Application
variable "create_demo_application" {
  description = "Створити демонстраційний Application"
  type        = bool
  default     = false
}

variable "demo_app_repo_url" {
  description = "URL репозиторію для демо додатку"
  type        = string
  default     = "https://github.com/argoproj/argocd-example-apps.git"
}

variable "demo_app_target_revision" {
  description = "Target revision для демо додатку"
  type        = string
  default     = "HEAD"
}

variable "demo_app_path" {
  description = "Шлях в репозиторії для демо додатку"
  type        = string
  default     = "guestbook"
}

variable "demo_app_namespace" {
  description = "Namespace для демо додатку"
  type        = string
  default     = "default"
}

# AppProject
variable "create_app_project" {
  description = "Створити AppProject"
  type        = bool
  default     = false
}

variable "app_project_name" {
  description = "Назва AppProject"
  type        = string
  default     = "default"
}

variable "app_project_source_repos" {
  description = "Дозволені source repositories для AppProject"
  type        = list(string)
  default     = ["*"]
}

variable "app_project_admin_groups" {
  description = "OIDC групи з admin правами"
  type        = list(string)
  default     = []
}

variable "app_project_developer_groups" {
  description = "OIDC групи з developer правами"
  type        = list(string)
  default     = []
}

# RBAC
variable "rbac_policy" {
  description = "Кастомна RBAC політика для Argo CD"
  type        = string
  default     = ""
}

variable "rbac_scopes" {
  description = "RBAC scopes для Argo CD"
  type        = string
  default     = "[groups]"
}

# Безпека
variable "enable_insecure" {
  description = "Увімкнути insecure режим (тільки для розробки)"
  type        = bool
  default     = false
}

variable "certificate_secret_name" {
  description = "Назва secret з TLS сертифікатом"
  type        = string
  default     = ""
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
    Module    = "argo-cd"
  }
}

# Додаткові налаштування
variable "timezone" {
  description = "Часовий пояс для Argo CD"
  type        = string
  default     = "UTC"
}

variable "log_level" {
  description = "Рівень логування для Argo CD"
  type        = string
  default     = "info"
  
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level повинен бути одним з: debug, info, warn, error."
  }
}

variable "log_format" {
  description = "Формат логування для Argo CD"
  type        = string
  default     = "text"
  
  validation {
    condition     = contains(["text", "json"], var.log_format)
    error_message = "Log format повинен бути text або json."
  }
}

variable "server_extra_args" {
  description = "Додаткові аргументи для Argo CD Server"
  type        = list(string)
  default     = []
}

variable "controller_extra_args" {
  description = "Додаткові аргументи для Application Controller"
  type        = list(string)
  default     = []
}

variable "repo_server_extra_args" {
  description = "Додаткові аргументи для Repo Server"
  type        = list(string)
  default     = []
}

# Webhook налаштування
variable "enable_webhooks" {
  description = "Увімкнути webhook підтримку"
  type        = bool
  default     = true
}

variable "webhook_github_secret" {
  description = "Secret для GitHub webhooks"
  type        = string
  default     = ""
  sensitive   = true
}

variable "webhook_gitlab_secret" {
  description = "Secret для GitLab webhooks"
  type        = string
  default     = ""
  sensitive   = true
}

# Sync налаштування
variable "sync_timeout" {
  description = "Timeout для sync операцій (секунди)"
  type        = number
  default     = 300
  
  validation {
    condition     = var.sync_timeout >= 60 && var.sync_timeout <= 3600
    error_message = "Sync timeout повинен бути від 60 до 3600 секунд."
  }
}

variable "self_heal_timeout" {
  description = "Timeout для self-heal операцій (секунди)"
  type        = number
  default     = 5
  
  validation {
    condition     = var.self_heal_timeout >= 1 && var.self_heal_timeout <= 60
    error_message = "Self-heal timeout повинен бути від 1 до 60 секунд."
  }
}