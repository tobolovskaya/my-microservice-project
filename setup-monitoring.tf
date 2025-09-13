# Налаштування моніторингу (Prometheus + Grafana)
# Цей файл використовується для початкового налаштування моніторингу

terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Namespace для моніторингу
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# Helm release для Prometheus + Grafana
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    file("${path.root}/monitoring-values.yaml")
  ]

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.ingress.enabled"
    value = var.grafana_ingress_enabled
  }

  set {
    name  = "grafana.ingress.hosts[0]"
    value = var.grafana_ingress_hostname
  }

  timeout = 600
  wait    = true

  depends_on = [kubernetes_namespace.monitoring]
}

# Змінні для моніторингу
variable "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "grafana_ingress_enabled" {
  description = "Увімкнути Ingress для Grafana"
  type        = bool
  default     = false
}

variable "grafana_ingress_hostname" {
  description = "Hostname для Grafana Ingress"
  type        = string
  default     = "grafana.local"
}

# Виводи
output "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "prometheus_url" {
  description = "URL для доступу до Prometheus"
  value       = "http://localhost:9090 (використовуйте kubectl port-forward)"
}

output "grafana_url" {
  description = "URL для доступу до Grafana"
  value       = "http://localhost:3000 (використовуйте kubectl port-forward)"
}