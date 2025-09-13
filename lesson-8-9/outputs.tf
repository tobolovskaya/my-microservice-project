# S3 Backend outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.s3_backend.bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.s3_backend.dynamodb_table_name
}

# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# ECR outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

# EKS outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "kubectl_config_command" {
  description = "kubectl config command"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_id}"
}

# Jenkins outputs
output "jenkins_url" {
  description = "Jenkins URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_admin_password_command" {
  description = "Command to get Jenkins admin password"
  value       = module.jenkins.admin_password_command
}

# Argo CD outputs
output "argocd_url" {
  description = "Argo CD URL"
  value       = module.argo_cd.argocd_url
}

output "argocd_admin_password_command" {
  description = "Command to get Argo CD admin password"
  value       = module.argo_cd.admin_password_command
}

# Useful commands
output "useful_commands" {
  description = "Useful commands for managing the infrastructure"
  value = {
    kubectl_config    = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_id}"
    jenkins_password  = module.jenkins.admin_password_command
    argocd_password   = module.argo_cd.admin_password_command
    jenkins_url       = module.jenkins.jenkins_url
    argocd_url        = module.argo_cd.argocd_url
  }
}