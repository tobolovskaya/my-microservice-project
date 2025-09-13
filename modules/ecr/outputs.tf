# Виведення інформації про ECR

# Основна інформація про репозиторій
output "repository_arn" {
  description = "ARN ECR репозиторію"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Назва ECR репозиторію"
  value       = aws_ecr_repository.main.name
}

output "repository_url" {
  description = "URL ECR репозиторію"
  value       = aws_ecr_repository.main.repository_url
}

output "registry_id" {
  description = "ID реєстру ECR"
  value       = aws_ecr_repository.main.registry_id
}

# Інформація для Docker команд
output "docker_push_commands" {
  description = "Команди для завантаження образу в ECR"
  value = [
    "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}",
    "docker build -t ${aws_ecr_repository.main.name} .",
    "docker tag ${aws_ecr_repository.main.name}:latest ${aws_ecr_repository.main.repository_url}:latest",
    "docker push ${aws_ecr_repository.main.repository_url}:latest"
  ]
}

output "docker_pull_command" {
  description = "Команда для завантаження образу з ECR"
  value       = "docker pull ${aws_ecr_repository.main.repository_url}:latest"
}

# Інформація про політики
output "lifecycle_policy_text" {
  description = "Текст політики життєвого циклу"
  value       = var.enable_lifecycle_policy ? aws_ecr_lifecycle_policy.main[0].policy : null
}

output "repository_policy_text" {
  description = "Текст політики репозиторію"
  value       = var.enable_cross_account_access ? aws_ecr_repository_policy.main[0].policy : null
}

# Налаштування безпеки
output "image_scanning_enabled" {
  description = "Чи увімкнено сканування образів"
  value       = var.scan_on_push
}

output "encryption_type" {
  description = "Тип шифрування репозиторію"
  value       = var.encryption_type
}

output "image_tag_mutability" {
  description = "Налаштування мутабельності тегів"
  value       = var.image_tag_mutability
}

# Інформація про реплікацію
output "replication_destinations" {
  description = "Регіони реплікації"
  value       = var.replication_regions
}

# Корисна інформація для CI/CD
output "ecr_login_command" {
  description = "Команда для логіну в ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}"
}

output "image_uri_template" {
  description = "Шаблон URI для образів"
  value       = "${aws_ecr_repository.main.repository_url}:TAG"
}

# Дані про поточний регіон
data "aws_region" "current" {}

# Статистика репозиторію
output "repository_creation_time" {
  description = "Час створення репозиторію"
  value       = aws_ecr_repository.main.id
}

# Інформація для Kubernetes
output "kubernetes_image_pull_secret" {
  description = "Команда для створення Kubernetes secret для ECR"
  value = "kubectl create secret docker-registry ecr-secret --docker-server=${aws_ecr_repository.main.repository_url} --docker-username=AWS --docker-password=$(aws ecr get-login-password --region ${data.aws_region.current.name})"
}

# Helm values для використання в чартах
output "helm_values" {
  description = "Значення для використання в Helm чартах"
  value = {
    image = {
      repository = aws_ecr_repository.main.repository_url
      tag        = "latest"
      pullPolicy = "Always"
    }
  }
}