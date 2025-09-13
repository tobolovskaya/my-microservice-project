# Виведення інформації про Jenkins

# Основна інформація
output "jenkins_namespace" {
  description = "Kubernetes namespace де встановлено Jenkins"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_release_name" {
  description = "Назва Helm release для Jenkins"
  value       = helm_release.jenkins.name
}

output "jenkins_chart_version" {
  description = "Версія Helm chart Jenkins"
  value       = helm_release.jenkins.version
}

# Доступ до Jenkins
output "jenkins_url" {
  description = "URL для доступу до Jenkins"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ? 
    "https://${var.ingress_hostname}" : 
    "http://${var.ingress_hostname}"
  ) : (
    var.service_type == "LoadBalancer" && var.create_load_balancer_service ? 
    "http://${try(kubernetes_service.jenkins_lb[0].status[0].load_balancer[0].ingress[0].hostname, "pending")}" :
    "http://localhost:8080 (використовуйте kubectl port-forward)"
  )
}

output "jenkins_internal_url" {
  description = "Внутрішній URL Jenkins в кластері"
  value       = "http://${helm_release.jenkins.name}-jenkins.${kubernetes_namespace.jenkins.metadata[0].name}.svc.cluster.local:8080"
}

# Креденшели
output "jenkins_admin_user" {
  description = "Ім'я адміністратора Jenkins"
  value       = var.admin_user
}

output "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins"
  value       = var.admin_password
  sensitive   = true
}

output "jenkins_admin_secret_name" {
  description = "Назва Kubernetes secret з паролем адміністратора"
  value       = kubernetes_secret.jenkins_admin.metadata[0].name
}

# Service Account
output "jenkins_service_account_name" {
  description = "Назва Service Account для Jenkins"
  value       = kubernetes_service_account.jenkins.metadata[0].name
}

output "jenkins_cluster_role_name" {
  description = "Назва Cluster Role для Jenkins"
  value       = kubernetes_cluster_role.jenkins.metadata[0].name
}

# Сховище
output "jenkins_pvc_name" {
  description = "Назва PersistentVolumeClaim для Jenkins"
  value       = var.create_pvc ? kubernetes_persistent_volume_claim.jenkins_home[0].metadata[0].name : null
}

output "jenkins_storage_size" {
  description = "Розмір сховища Jenkins"
  value       = var.storage_size
}

output "jenkins_storage_class" {
  description = "Storage class для Jenkins"
  value       = var.storage_class
}

# Мережеві ресурси
output "jenkins_service_name" {
  description = "Назва основного Kubernetes service для Jenkins"
  value       = "${helm_release.jenkins.name}-jenkins"
}

output "jenkins_service_type" {
  description = "Тип Kubernetes service для Jenkins"
  value       = var.service_type
}

output "jenkins_load_balancer_service_name" {
  description = "Назва LoadBalancer service (якщо створено)"
  value       = var.create_load_balancer_service ? kubernetes_service.jenkins_lb[0].metadata[0].name : null
}

output "jenkins_load_balancer_hostname" {
  description = "Hostname LoadBalancer (якщо доступний)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.jenkins_lb[0].status[0].load_balancer[0].ingress[0].hostname, null)
  ) : null
}

output "jenkins_load_balancer_ip" {
  description = "IP адреса LoadBalancer (якщо доступна)"
  value = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? (
    try(kubernetes_service.jenkins_lb[0].status[0].load_balancer[0].ingress[0].ip, null)
  ) : null
}

# Ingress
output "jenkins_ingress_name" {
  description = "Назва Ingress ресурсу (якщо створено)"
  value       = var.create_custom_ingress ? kubernetes_ingress_v1.jenkins[0].metadata[0].name : null
}

output "jenkins_ingress_hostname" {
  description = "Hostname для Ingress"
  value       = var.ingress_enabled ? var.ingress_hostname : null
}

output "jenkins_ingress_tls_secret" {
  description = "Назва TLS secret для Ingress"
  value       = var.ingress_tls_enabled ? var.ingress_tls_secret_name : null
}

# Auto Scaling
output "jenkins_hpa_name" {
  description = "Назва HorizontalPodAutoscaler (якщо увімкнено)"
  value       = var.enable_hpa ? kubernetes_horizontal_pod_autoscaler_v2.jenkins[0].metadata[0].name : null
}

output "jenkins_hpa_min_replicas" {
  description = "Мінімальна кількість реплік HPA"
  value       = var.enable_hpa ? var.hpa_min_replicas : null
}

output "jenkins_hpa_max_replicas" {
  description = "Максимальна кількість реплік HPA"
  value       = var.enable_hpa ? var.hpa_max_replicas : null
}

# Команди для доступу
output "kubectl_port_forward_command" {
  description = "Команда для port-forward до Jenkins"
  value       = "kubectl port-forward -n ${kubernetes_namespace.jenkins.metadata[0].name} svc/${helm_release.jenkins.name}-jenkins 8080:8080"
}

output "kubectl_get_admin_password_command" {
  description = "Команда для отримання пароля адміністратора"
  value       = "kubectl get secret -n ${kubernetes_namespace.jenkins.metadata[0].name} ${kubernetes_secret.jenkins_admin.metadata[0].name} -o jsonpath='{.data.jenkins-admin-password}' | base64 -d"
}

output "kubectl_logs_command" {
  description = "Команда для перегляду логів Jenkins"
  value       = "kubectl logs -n ${kubernetes_namespace.jenkins.metadata[0].name} -l app.kubernetes.io/instance=${helm_release.jenkins.name} -f"
}

# Helm інформація
output "helm_status_command" {
  description = "Команда для перевірки статусу Helm release"
  value       = "helm status ${helm_release.jenkins.name} -n ${kubernetes_namespace.jenkins.metadata[0].name}"
}

output "helm_values_command" {
  description = "Команда для перегляду Helm values"
  value       = "helm get values ${helm_release.jenkins.name} -n ${kubernetes_namespace.jenkins.metadata[0].name}"
}

# Конфігурація
output "jenkins_java_opts" {
  description = "Java опції для Jenkins"
  value       = var.java_opts
}

output "jenkins_plugins_list" {
  description = "Список встановлених плагінів"
  value       = var.install_plugins
}

# Моніторинг
output "jenkins_prometheus_enabled" {
  description = "Чи увімкнено Prometheus моніторинг"
  value       = var.enable_prometheus_monitoring
}

output "jenkins_prometheus_endpoint" {
  description = "Endpoint для Prometheus метрик"
  value       = var.enable_prometheus_monitoring ? "${helm_release.jenkins.name}-jenkins.${kubernetes_namespace.jenkins.metadata[0].name}.svc.cluster.local:8080/prometheus" : null
}

# Backup
output "jenkins_backup_enabled" {
  description = "Чи увімкнено автоматичне резервне копіювання"
  value       = var.enable_backup
}

output "jenkins_backup_schedule" {
  description = "Розклад резервного копіювання"
  value       = var.enable_backup ? var.backup_schedule : null
}

# Інтеграція з AWS
output "jenkins_aws_region" {
  description = "AWS регіон для інтеграції"
  value       = var.aws_region != "" ? var.aws_region : null
}

output "jenkins_ecr_registry_url" {
  description = "URL ECR registry"
  value       = var.ecr_registry_url != "" ? var.ecr_registry_url : null
}

# Статус розгортання
output "jenkins_deployment_status" {
  description = "Статус розгортання Jenkins"
  value       = helm_release.jenkins.status
}

output "jenkins_chart_repository" {
  description = "Helm repository для Jenkins chart"
  value       = var.helm_repository
}

# Корисна інформація для CI/CD
output "jenkins_webhook_url" {
  description = "URL для GitHub/GitLab webhooks"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ? 
    "https://${var.ingress_hostname}/github-webhook/" : 
    "http://${var.ingress_hostname}/github-webhook/"
  ) : null
}

output "jenkins_api_url" {
  description = "URL для Jenkins API"
  value = var.ingress_enabled ? (
    var.ingress_tls_enabled ? 
    "https://${var.ingress_hostname}/api/" : 
    "http://${var.ingress_hostname}/api/"
  ) : null
}

# Troubleshooting команди
output "troubleshooting_commands" {
  description = "Корисні команди для діагностики"
  value = {
    check_pods = "kubectl get pods -n ${kubernetes_namespace.jenkins.metadata[0].name} -l app.kubernetes.io/instance=${helm_release.jenkins.name}"
    describe_pod = "kubectl describe pod -n ${kubernetes_namespace.jenkins.metadata[0].name} -l app.kubernetes.io/instance=${helm_release.jenkins.name}"
    check_pvc = var.create_pvc ? "kubectl get pvc -n ${kubernetes_namespace.jenkins.metadata[0].name} ${kubernetes_persistent_volume_claim.jenkins_home[0].metadata[0].name}" : null
    check_service = "kubectl get svc -n ${kubernetes_namespace.jenkins.metadata[0].name} ${helm_release.jenkins.name}-jenkins"
    check_ingress = var.ingress_enabled ? "kubectl get ingress -n ${kubernetes_namespace.jenkins.metadata[0].name}" : null
    helm_history = "helm history ${helm_release.jenkins.name} -n ${kubernetes_namespace.jenkins.metadata[0].name}"
  }
}