# Загальні виводи ресурсів

# VPC виводи
output "vpc_id" {
  description = "ID VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "ID приватних підмереж"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "ID публічних підмереж"
  value       = module.vpc.public_subnet_ids
}

# RDS виводи
output "database_endpoint" {
  description = "Endpoint бази даних"
  value       = module.rds.endpoint
}

output "database_port" {
  description = "Порт бази даних"
  value       = module.rds.port
}

output "database_name" {
  description = "Назва бази даних"
  value       = module.rds.database_name
}

output "database_username" {
  description = "Ім'я користувача бази даних"
  value       = module.rds.username
  sensitive   = true
}

output "security_group_id" {
  description = "ID Security Group для бази даних"
  value       = module.rds.security_group_id
}

output "subnet_group_name" {
  description = "Назва DB Subnet Group"
  value       = module.rds.subnet_group_name
}

output "parameter_group_name" {
  description = "Назва Parameter Group"
  value       = module.rds.parameter_group_name
}

# EKS виводи
output "eks_cluster_id" {
  description = "ID EKS кластера"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "Назва EKS кластера"
  value       = module.eks.cluster_name
}

output "kubectl_config_command" {
  description = "Команда для налаштування kubectl"
  value       = module.eks.kubectl_config_command
}

output "cluster_security_group_id" {
  description = "ID Security Group EKS кластера"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "ID Security Group для EKS node groups"
  value       = module.eks.node_security_group_id
}

# ECR виводи
output "ecr_repository_url" {
  description = "URL ECR репозиторію"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN ECR репозиторію"
  value       = module.ecr.repository_arn
}

output "ecr_registry_id" {
  description = "ID ECR реєстру"
  value       = module.ecr.registry_id
}

output "ecr_docker_push_commands" {
  description = "Команди для завантаження образу в ECR"
  value       = module.ecr.docker_push_commands
}

output "ecr_login_command" {
  description = "Команда для логіну в ECR"
  value       = module.ecr.ecr_login_command
}

# Jenkins виводи
output "jenkins_url" {
  description = "URL для доступу до Jenkins"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_user" {
  description = "Ім'я адміністратора Jenkins"
  value       = module.jenkins.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Kubernetes namespace Jenkins"
  value       = module.jenkins.jenkins_namespace
}

output "kubectl_port_forward_command" {
  description = "Команда для port-forward до Jenkins"
  value       = module.jenkins.kubectl_port_forward_command
}

output "jenkins_webhook_url" {
  description = "URL для GitHub/GitLab webhooks"
  value       = module.jenkins.jenkins_webhook_url
}

output "jenkins_api_url" {
  description = "URL для Jenkins API"
  value       = module.jenkins.jenkins_api_url
}

# Argo CD виводи
output "argocd_url" {
  description = "URL для доступу до Argo CD"
  value       = module.argocd.argocd_url
}

output "argocd_admin_password" {
  description = "Пароль адміністратора Argo CD"
  value       = module.argocd.argocd_admin_password
  sensitive   = true
}

output "argocd_namespace" {
  description = "Kubernetes namespace Argo CD"
  value       = module.argocd.argocd_namespace
}

output "argocd_cli_login_command" {
  description = "Команда для логіну через Argo CD CLI"
  value       = module.argocd.argocd_cli_login_command
  sensitive   = true
}

output "argocd_webhook_urls" {
  description = "URLs для Git webhooks"
  value       = module.argocd.argocd_webhook_urls
}

output "argocd_api_url" {
  description = "URL для Argo CD API"
  value       = module.argocd.argocd_api_url
}

# Моніторинг виводи
output "prometheus_url" {
  description = "URL для доступу до Prometheus"
  value       = "http://localhost:9090 (використовуйте kubectl port-forward)"
}

output "grafana_url" {
  description = "URL для доступу до Grafana"
  value       = "http://localhost:3000 (використовуйте kubectl port-forward)"
}

output "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  value       = var.grafana_admin_password
  sensitive   = true
}

# Команди для доступу до моніторингу
output "prometheus_port_forward_command" {
  description = "Команда для port-forward до Prometheus"
  value       = "kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring"
}

output "grafana_port_forward_command" {
  description = "Команда для port-forward до Grafana"
  value       = "kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
}