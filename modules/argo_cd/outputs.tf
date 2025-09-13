# Виведення інформації про Argo CD

# Основна інформація
output "argocd_namespace" {
  description = "Kubernetes namespace де встановлено Argo CD"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_release_name" {
  description = "Назва Helm release для Argo CD"
  value       = helm_release.argocd.name
}

output "argocd_chart_version" {
  description = "Версія Helm chart Argo CD"
  value       = helm_release.argocd.version
}

# Доступ до Argo CD
output "argocd_url" {
  description = "URL для доступу до Argo CD"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ? 
    "https://${var.ingress_hostname}" : 
    "http://${var.ingress_hostname}"
  ) : (
    var.service_type == "LoadBalancer" && var.create_load_balancer_service ? 
    "http://${try(kubernetes_service.argocd_lb[0].status[0].load_balancer[0].ingress[0].hostname, "pending")}" :
    "http://localhost:8080 (використовуйте kubectl port-forward)"
  )
}

output "argocd_internal_url" {
  description = "Внутрішній URL Argo CD в кластері"
  value       = "http://${helm_release.argocd.name}-argocd-server.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local"
}

# Креденшели
output "argocd_admin_password" {
  description = "Пароль адміністратора Argo CD"
  value       = var.admin_password
  sensitive   = true
}

output "argocd_admin_secret_name" {
  description = "Назва Kubernetes secret з паролем адміністратора"
  value       = kubernetes_secret.argocd_admin.metadata[0].name
}

# Service Account
output "argocd_service_account_name" {
  description = "Назва Service Account для Argo CD"
  value       = kubernetes_service_account.argocd.metadata[0].name
}

output "argocd_cluster_role_name" {
  description = "Назва Cluster Role для Argo CD"
  value       = kubernetes_cluster_role.argocd.metadata[0].name
}

# Мережеві ресурси
output "argocd_service_name" {
  description = "Назва основного Kubernetes service для Argo CD"
  value       = "${helm_release.argocd.name}-argocd-server"
}

output "argocd_service_type" {
  description = "Тип Kubernetes service для Argo CD"
  value       = var.service_type
}

output "argocd_load_balancer_service_name" {
  description = "Назва LoadBalancer service (якщо створено)"
  value       = var.create_load_balancer_service ? kubernetes_service.argocd_lb[0].metadata[0].name : null
}

output "argocd_load_balancer_hostname" {
  description = "Hostname LoadBalancer (якщо доступний)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.argocd_lb[0].status[0].load_balancer[0].ingress[0].hostname, null)
  ) : null
}

output "argocd_load_balancer_ip" {
  description = "IP адреса LoadBalancer (якщо доступна)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.argocd_lb[0].status[0].load_balancer[0].ingress[0].ip, null)
  ) : null
}

# Ingress
output "argocd_ingress_name" {
  description = "Назва Ingress ресурсу (якщо створено)"
  value       = var.create_custom_ingress ? kubernetes_ingress_v1.argocd[0].metadata[0].name : null
}

output "argocd_ingress_hostname" {
  description = "Hostname для Ingress"
  value       = var.ingress_enabled ? var.ingress_hostname : null
}

output "argocd_ingress_tls_secret" {
  description = "Назва TLS secret для Ingress"
  value       = var.ingress_tls_enabled ? var.ingress_tls_secret_name : null
}

# Auto Scaling
output "argocd_hpa_name" {
  description = "Назва HorizontalPodAutoscaler (якщо увімкнено)"
  value       = var.enable_hpa ? kubernetes_horizontal_pod_autoscaler_v2.argocd_server[0].metadata[0].name : null
}

output "argocd_hpa_min_replicas" {
  description = "Мінімальна кількість реплік HPA"
  value       = var.enable_hpa ? var.hpa_min_replicas : null
}

output "argocd_hpa_max_replicas" {
  description = "Максимальна кількість реплік HPA"
  value       = var.enable_hpa ? var.hpa_max_replicas : null
}

# Команди для доступу
output "kubectl_port_forward_command" {
  description = "Команда для port-forward до Argo CD"
  value       = "kubectl port-forward -n ${kubernetes_namespace.argocd.metadata[0].name} svc/${helm_release.argocd.name}-argocd-server 8080:80"
}

output "kubectl_get_admin_password_command" {
  description = "Команда для отримання пароля адміністратора"
  value       = "kubectl get secret -n ${kubernetes_namespace.argocd.metadata[0].name} ${kubernetes_secret.argocd_admin.metadata[0].name} -o jsonpath='{.data.password}' | base64 -d"
}

output "kubectl_logs_command" {
  description = "Команда для перегляду логів Argo CD"
  value       = "kubectl logs -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/name=argocd-server -f"
}

# Helm інформація
output "helm_status_command" {
  description = "Команда для перевірки статусу Helm release"
  value       = "helm status ${helm_release.argocd.name} -n ${kubernetes_namespace.argocd.metadata[0].name}"
}

output "helm_values_command" {
  description = "Команда для перегляду Helm values"
  value       = "helm get values ${helm_release.argocd.name} -n ${kubernetes_namespace.argocd.metadata[0].name}"
}

# CLI команди
output "argocd_cli_login_command" {
  description = "Команда для логіну через Argo CD CLI"
  value = var.ingress_enabled ? (
    "argocd login ${var.ingress_hostname} --username admin --password '${var.admin_password}'"
  ) : (
    "argocd login localhost:8080 --username admin --password '${var.admin_password}' --insecure"
  )
  sensitive = true
}

output "argocd_cli_context_command" {
  description = "Команда для встановлення контексту Argo CD CLI"
  value = var.ingress_enabled ? (
    "argocd context ${var.ingress_hostname}"
  ) : (
    "argocd context localhost:8080"
  )
}

# GitOps інформація
output "argocd_applications_command" {
  description = "Команда для перегляду Applications"
  value       = "argocd app list"
}

output "argocd_sync_command" {
  description = "Команда для синхронізації додатку"
  value       = "argocd app sync <app-name>"
}

# Demo Application
output "demo_application_name" {
  description = "Назва демонстраційного Application (якщо створено)"
  value       = var.create_demo_application ? "demo-app" : null
}

output "demo_application_namespace" {
  description = "Namespace демонстраційного Application"
  value       = var.create_demo_application ? var.demo_app_namespace : null
}

# AppProject
output "app_project_name" {
  description = "Назва AppProject (якщо створено)"
  value       = var.create_app_project ? var.app_project_name : null
}

# Моніторинг
output "argocd_prometheus_enabled" {
  description = "Чи увімкнено Prometheus моніторинг"
  value       = var.enable_prometheus_monitoring
}

output "argocd_metrics_endpoints" {
  description = "Endpoints для Prometheus метрик"
  value = var.enable_metrics ? {
    server     = "${helm_release.argocd.name}-argocd-server-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8083"
    controller = "${helm_release.argocd.name}-argocd-application-controller-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8082"
    repo_server = "${helm_release.argocd.name}-argocd-repo-server-metrics.${kubernetes_namespace.argocd.metadata[0].name}.svc.cluster.local:8084"
  } : null
}

# Функціональність
output "argocd_features_enabled" {
  description = "Увімкнені функції Argo CD"
  value = {
    high_availability = var.enable_ha
    metrics          = var.enable_metrics
    notifications    = var.enable_notifications
    applicationset   = var.enable_applicationset
    dex             = var.enable_dex
    webhooks        = var.enable_webhooks
  }
}

# Статус розгортання
output "argocd_deployment_status" {
  description = "Статус розгортання Argo CD"
  value       = helm_release.argocd.status
}

output "argocd_chart_repository" {
  description = "Helm repository для Argo CD chart"
  value       = var.helm_repository
}

# Корисна інформація для GitOps
output "argocd_webhook_urls" {
  description = "URLs для Git webhooks"
  value = var.ingress_enabled ? {
    github = var.ingress_tls_enabled ? 
      "https://${var.ingress_hostname}/api/webhook" : 
      "http://${var.ingress_hostname}/api/webhook"
    gitlab = var.ingress_tls_enabled ? 
      "https://${var.ingress_hostname}/api/webhook" : 
      "http://${var.ingress_hostname}/api/webhook"
  } : null
}

output "argocd_api_url" {
  description = "URL для Argo CD API"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ? 
    "https://${var.ingress_hostname}/api/v1/" : 
    "http://${var.ingress_hostname}/api/v1/"
  ) : null
}

# Troubleshooting команди
output "troubleshooting_commands" {
  description = "Корисні команди для діагностики"
  value = {
    check_pods = "kubectl get pods -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/part-of=argocd"
    describe_server = "kubectl describe pod -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/name=argocd-server"
    describe_controller = "kubectl describe pod -n ${kubernetes_namespace.argocd.metadata[0].name} -l app.kubernetes.io/name=argocd-application-controller"
    check_service = "kubectl get svc -n ${kubernetes_namespace.argocd.metadata[0].name} ${helm_release.argocd.name}-argocd-server"
    check_ingress = var.ingress_enabled ? "kubectl get ingress -n ${kubernetes_namespace.argocd.metadata[0].name}" : null
    helm_history = "helm history ${helm_release.argocd.name} -n ${kubernetes_namespace.argocd.metadata[0].name}"
    check_applications = "kubectl get applications -n ${kubernetes_namespace.argocd.metadata[0].name}"
    check_appprojects = "kubectl get appprojects -n ${kubernetes_namespace.argocd.metadata[0].name}"
  }
}

# Конфігурація для інтеграції з CI/CD
output "argocd_integration_info" {
  description = "Інформація для інтеграції з CI/CD системами"
  value = {
    server_url = var.ingress_enabled ? (
      var.ingress_tls_enabled ? 
      "https://${var.ingress_hostname}" : 
      "http://${var.ingress_hostname}"
    ) : "http://localhost:8080"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    admin_username = "admin"
    cli_version = "v2.9.3"
  }
  sensitive = false
}