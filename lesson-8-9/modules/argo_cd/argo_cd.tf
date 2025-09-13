# Argo CD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = var.argocd_namespace

  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  depends_on = [kubernetes_namespace.argocd]
}

# Kubernetes namespace for Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      name        = var.argocd_namespace
      environment = "lesson-8-9"
    }
  }
}

# Argo CD Applications Helm Chart
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = var.argocd_namespace

  set {
    name  = "gitRepository.url"
    value = var.git_repository_url
  }

  set {
    name  = "gitRepository.targetRevision"
    value = "HEAD"
  }

  set {
    name  = "applications.django-app.enabled"
    value = "true"
  }

  set {
    name  = "applications.django-app.path"
    value = "charts/django-app"
  }

  set {
    name  = "applications.django-app.namespace"
    value = "default"
  }

  depends_on = [helm_release.argocd]
}

# Service Account for Argo CD with necessary permissions
resource "kubernetes_service_account" "argocd" {
  metadata {
    name      = "argocd-sa"
    namespace = var.argocd_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.argocd.arn
    }
  }

  depends_on = [kubernetes_namespace.argocd]
}

# IAM Role for Argo CD
resource "aws_iam_role" "argocd" {
  name = "${var.cluster_name}-argocd-role"

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
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.argocd_namespace}:argocd-sa"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.cluster_name}-argocd-role"
    Environment = "lesson-8-9"
  }
}

# Data source for EKS cluster
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# ClusterRole for Argo CD
resource "kubernetes_cluster_role" "argocd" {
  metadata {
    name = "argocd-application-controller"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }
}

# ClusterRoleBinding for Argo CD
resource "kubernetes_cluster_role_binding" "argocd" {
  metadata {
    name = "argocd-application-controller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argocd.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-application-controller"
    namespace = var.argocd_namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-server"
    namespace = var.argocd_namespace
  }
}