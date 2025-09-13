# Jenkins Helm Release
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.jenkins_version
  namespace  = var.jenkins_namespace

  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "controller.serviceType"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.adminPassword"
    value = var.jenkins_admin_password
  }

  set {
    name  = "persistence.size"
    value = "20Gi"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "2000m"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "4Gi"
  }

  # Jenkins Configuration as Code
  set {
    name  = "controller.JCasC.configScripts.welcome-message"
    value = "jenkins:\n  systemMessage: Welcome to Jenkins CI/CD for lesson-8-9!"
  }

  depends_on = [kubernetes_namespace.jenkins]
}

# Kubernetes namespace for Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
    labels = {
      name        = var.jenkins_namespace
      environment = "lesson-8-9"
    }
  }
}

# Service Account for Jenkins with ECR permissions
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins-sa"
    namespace = var.jenkins_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins.arn
    }
  }

  depends_on = [kubernetes_namespace.jenkins]
}

# IAM Role for Jenkins
resource "aws_iam_role" "jenkins" {
  name = "${var.cluster_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
        }
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.jenkins_namespace}:jenkins-sa"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-jenkins-role"
    Environment = "lesson-8-9"
  }
}

# IAM Policy for Jenkins ECR access
resource "aws_iam_policy" "jenkins_ecr" {
  name        = "${var.cluster_name}-jenkins-ecr-policy"
  description = "IAM policy for Jenkins ECR access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  policy_arn = aws_iam_policy.jenkins_ecr.arn
  role       = aws_iam_role.jenkins.name
}

# Data source for EKS cluster
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# ConfigMap for Kaniko configuration
resource "kubernetes_config_map" "kaniko_config" {
  metadata {
    name      = "kaniko-config"
    namespace = var.jenkins_namespace
  }

  data = {
    "config.json" = jsonencode({
      credsStore = "ecr-login"
    })
  }

  depends_on = [kubernetes_namespace.jenkins]
}

# Secret for Git credentials (you'll need to update this with actual credentials)
resource "kubernetes_secret" "git_credentials" {
  metadata {
    name      = "git-credentials"
    namespace = var.jenkins_namespace
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = base64encode("git")
    password = base64encode("your-git-token-here") # Replace with actual token
  }

  depends_on = [kubernetes_namespace.jenkins]
}