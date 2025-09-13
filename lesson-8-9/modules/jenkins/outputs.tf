output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://jenkins.${var.jenkins_namespace}.svc.cluster.local:8080"
}

output "jenkins_external_url" {
  description = "Jenkins external URL (LoadBalancer)"
  value       = "kubectl get service jenkins -n ${var.jenkins_namespace} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "admin_password_command" {
  description = "Command to get Jenkins admin password"
  value       = "kubectl get secret jenkins -n ${var.jenkins_namespace} -o jsonpath='{.data.jenkins-admin-password}' | base64 --decode"
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = var.jenkins_namespace
}

output "jenkins_service_account_name" {
  description = "Jenkins service account name"
  value       = kubernetes_service_account.jenkins.metadata[0].name
}

output "jenkins_iam_role_arn" {
  description = "Jenkins IAM role ARN"
  value       = aws_iam_role.jenkins.arn
}