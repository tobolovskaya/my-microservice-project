output "argocd_url" {
  description = "Argo CD URL"
  value       = "http://argocd-server.${var.argocd_namespace}.svc.cluster.local"
}

output "argocd_external_url" {
  description = "Argo CD external URL (LoadBalancer)"
  value       = "kubectl get service argocd-server -n ${var.argocd_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "admin_password_command" {
  description = "Command to get Argo CD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = var.argocd_namespace
}

output "argocd_service_account_name" {
  description = "Argo CD service account name"
  value       = kubernetes_service_account.argocd.metadata[0].name
}

output "argocd_iam_role_arn" {
  description = "Argo CD IAM role ARN"
  value       = aws_iam_role.argocd.arn
}