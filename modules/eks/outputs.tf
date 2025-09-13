# Виведення інформації про EKS кластер

# Основна інформація про кластер
output "cluster_id" {
  description = "ID EKS кластера"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Назва EKS кластера"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN EKS кластера"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Версія Kubernetes кластера"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Версія платформи EKS"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Статус EKS кластера"
  value       = aws_eks_cluster.main.status
}

# Сертифікат кластера
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data для підключення до кластера"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# OIDC інформація
output "cluster_oidc_issuer_url" {
  description = "URL OIDC identity provider для кластера"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN OIDC Identity Provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

# Security Groups
output "cluster_security_group_id" {
  description = "ID Security Group кластера"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "ID Security Group для node groups"
  value       = aws_security_group.node_group.id
}

# IAM ролі
output "cluster_iam_role_arn" {
  description = "ARN IAM ролі кластера"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_arn" {
  description = "ARN IAM ролі node groups"
  value       = aws_iam_role.node_group.arn
}

output "ebs_csi_driver_iam_role_arn" {
  description = "ARN IAM ролі EBS CSI Driver"
  value       = var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi_driver[0].arn : null
}

# Node Groups інформація
output "node_groups" {
  description = "Інформація про node groups"
  value = {
    for ng in aws_eks_node_group.main : ng.node_group_name => {
      arn           = ng.arn
      status        = ng.status
      capacity_type = ng.capacity_type
      instance_types = ng.instance_types
      ami_type      = ng.ami_type
      node_role_arn = ng.node_role_arn
      subnet_ids    = ng.subnet_ids
      scaling_config = ng.scaling_config
      labels        = ng.labels
    }
  }
}

# Add-ons інформація
output "ebs_csi_addon_arn" {
  description = "ARN EBS CSI Driver addon"
  value       = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi_driver[0].arn : null
}

output "ebs_csi_addon_status" {
  description = "Статус EBS CSI Driver addon"
  value       = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi_driver[0].status : null
}

# Команди для підключення
output "kubectl_config_command" {
  description = "Команда для налаштування kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
}

output "kubeconfig" {
  description = "Конфігурація kubeconfig для підключення до кластера"
  value = {
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = aws_eks_cluster.main.name
      cluster = {
        server                     = aws_eks_cluster.main.endpoint
        certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
      }
    }]
    contexts = [{
      name = aws_eks_cluster.main.name
      context = {
        cluster = aws_eks_cluster.main.name
        user    = aws_eks_cluster.main.name
      }
    }]
    current-context = aws_eks_cluster.main.name
    users = [{
      name = aws_eks_cluster.main.name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            aws_eks_cluster.main.name,
            "--region",
            data.aws_region.current.name
          ]
        }
      }
    }]
  }
  sensitive = true
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "Назва CloudWatch Log Group для кластера"
  value       = "/aws/eks/${aws_eks_cluster.main.name}/cluster"
}

# Мережева інформація
output "vpc_id" {
  description = "ID VPC кластера"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "ID підмереж кластера"
  value       = var.subnet_ids
}

# Корисна інформація для CI/CD
output "cluster_info" {
  description = "Загальна інформація про кластер для використання в CI/CD"
  value = {
    name                = aws_eks_cluster.main.name
    endpoint            = aws_eks_cluster.main.endpoint
    region              = data.aws_region.current.name
    certificate_authority = aws_eks_cluster.main.certificate_authority[0].data
    oidc_issuer_url     = aws_eks_cluster.main.identity[0].oidc[0].issuer
  }
  sensitive = true
}

# Helm values для різних чартів
output "helm_values" {
  description = "Значення для використання в Helm чартах"
  value = {
    cluster = {
      name     = aws_eks_cluster.main.name
      endpoint = aws_eks_cluster.main.endpoint
      region   = data.aws_region.current.name
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.node_group.arn
      }
    }
  }
}