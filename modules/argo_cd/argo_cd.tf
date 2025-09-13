# Argo CD Helm Release модуль

# Namespace для Argo CD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
      "app.kubernetes.io/name" = "argocd"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# Secret для Argo CD admin password
resource "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "argocd-secret"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    password = var.admin_password
  }

  type = "Opaque"
}

# ServiceAccount для Argo CD з необхідними правами
resource "kubernetes_service_account" "argocd" {
  metadata {
    name      = "argocd-application-controller"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "argocd-application-controller"
      "app.kubernetes.io/instance" = var.release_name
      "app.kubernetes.io/component" = "application-controller"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  automount_service_account_token = true
}

# ClusterRole для Argo CD
resource "kubernetes_cluster_role" "argocd" {
  metadata {
    name = "argocd-application-controller"
    labels = {
      "app.kubernetes.io/name" = "argocd-application-controller"
      "app.kubernetes.io/instance" = var.release_name
      "app.kubernetes.io/component" = "application-controller"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    non_resource_urls = ["*"]
    verbs            = ["*"]
  }
}

# ClusterRoleBinding для Argo CD
resource "kubernetes_cluster_role_binding" "argocd" {
  metadata {
    name = "argocd-application-controller"
    labels = {
      "app.kubernetes.io/name" = "argocd-application-controller"
      "app.kubernetes.io/instance" = var.release_name
      "app.kubernetes.io/component" = "application-controller"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.argocd.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.argocd.metadata[0].name
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }
}

# ConfigMap для додаткових Argo CD конфігурацій
resource "kubernetes_config_map" "argocd_config" {
  count = length(var.argocd_config_files) > 0 ? 1 : 0

  metadata {
    name      = "argocd-cmd-params-cm"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "argocd-cmd-params-cm"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = var.argocd_config_files
}

# Helm Release для Argo CD
resource "helm_release" "argocd" {
  name       = var.release_name
  repository = var.helm_repository
  chart      = var.helm_chart
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Використання values.yaml файлу
  values = [
    file("${path.module}/values.yaml"),
    var.additional_values
  ]

  # Динамічні значення
  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(var.admin_password)
  }

  set {
    name  = "global.domain"
    value = var.ingress_hostname
  }

  set {
    name  = "server.ingress.enabled"
    value = var.ingress_enabled
  }

  set {
    name  = "server.ingress.hostname"
    value = var.ingress_hostname
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = var.ingress_class_name
  }

  set {
    name  = "server.service.type"
    value = var.service_type
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = var.controller_resources.requests.cpu
  }

  set {
    name  = "controller.resources.requests.memory"
    value = var.controller_resources.requests.memory
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = var.controller_resources.limits.cpu
  }

  set {
    name  = "controller.resources.limits.memory"
    value = var.controller_resources.limits.memory
  }

  set {
    name  = "server.resources.requests.cpu"
    value = var.server_resources.requests.cpu
  }

  set {
    name  = "server.resources.requests.memory"
    value = var.server_resources.requests.memory
  }

  set {
    name  = "server.resources.limits.cpu"
    value = var.server_resources.limits.cpu
  }

  set {
    name  = "server.resources.limits.memory"
    value = var.server_resources.limits.memory
  }

  set {
    name  = "repoServer.resources.requests.cpu"
    value = var.repo_server_resources.requests.cpu
  }

  set {
    name  = "repoServer.resources.requests.memory"
    value = var.repo_server_resources.requests.memory
  }

  set {
    name  = "repoServer.resources.limits.cpu"
    value = var.repo_server_resources.limits.cpu
  }

  set {
    name  = "repoServer.resources.limits.memory"
    value = var.repo_server_resources.limits.memory
  }

  # High Availability налаштування
  set {
    name  = "controller.replicas"
    value = var.enable_ha ? var.controller_replicas : 1
  }

  set {
    name  = "server.replicas"
    value = var.enable_ha ? var.server_replicas : 1
  }

  set {
    name  = "repoServer.replicas"
    value = var.enable_ha ? var.repo_server_replicas : 1
  }

  # Redis HA
  set {
    name  = "redis-ha.enabled"
    value = var.enable_ha
  }

  set {
    name  = "redis.enabled"
    value = !var.enable_ha
  }

  # Metrics
  set {
    name  = "controller.metrics.enabled"
    value = var.enable_metrics
  }

  set {
    name  = "server.metrics.enabled"
    value = var.enable_metrics
  }

  set {
    name  = "repoServer.metrics.enabled"
    value = var.enable_metrics
  }

  # Notifications
  set {
    name  = "notifications.enabled"
    value = var.enable_notifications
  }

  # ApplicationSet
  set {
    name  = "applicationSet.enabled"
    value = var.enable_applicationset
  }

  # Dex (OIDC)
  set {
    name  = "dex.enabled"
    value = var.enable_dex
  }

  depends_on = [
    kubernetes_namespace.argocd,
    kubernetes_service_account.argocd,
    kubernetes_cluster_role_binding.argocd,
    kubernetes_secret.argocd_admin
  ]

  timeout = var.helm_timeout

  # Очікування готовності
  wait          = true
  wait_for_jobs = true
}

# Service для доступу до Argo CD (якщо потрібен LoadBalancer)
resource "kubernetes_service" "argocd_lb" {
  count = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? 1 : 0

  metadata {
    name      = "${var.release_name}-server-loadbalancer"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "argocd-server"
      "app.kubernetes.io/instance" = var.release_name
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/part-of" = "argocd"
    }
    annotations = var.load_balancer_annotations
  }

  spec {
    type = "LoadBalancer"
    
    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8080
      protocol    = "TCP"
    }

    selector = {
      "app.kubernetes.io/name" = "argocd-server"
      "app.kubernetes.io/instance" = var.release_name
    }

    load_balancer_source_ranges = var.load_balancer_source_ranges
  }
}

# Ingress для Argo CD (якщо увімкнено)
resource "kubernetes_ingress_v1" "argocd" {
  count = var.ingress_enabled && var.create_custom_ingress ? 1 : 0

  metadata {
    name      = "${var.release_name}-server-ingress"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "argocd-server"
      "app.kubernetes.io/instance" = var.release_name
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/part-of" = "argocd"
    }
    annotations = merge(
      {
        "kubernetes.io/ingress.class" = var.ingress_class_name
        "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
        "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        "nginx.ingress.kubernetes.io/backend-protocol" = "GRPC"
      },
      var.ingress_annotations
    )
  }

  spec {
    dynamic "tls" {
      for_each = var.ingress_tls_enabled ? [1] : []
      content {
        hosts       = [var.ingress_hostname]
        secret_name = var.ingress_tls_secret_name
      }
    }

    rule {
      host = var.ingress_hostname
      
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = "${var.release_name}-argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# HorizontalPodAutoscaler для Argo CD Server (опціонально)
resource "kubernetes_horizontal_pod_autoscaler_v2" "argocd_server" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "${var.release_name}-server-hpa"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "argocd-server"
      "app.kubernetes.io/instance" = var.release_name
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "${var.release_name}-argocd-server"
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_target_cpu_utilization
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_target_memory_utilization
        }
      }
    }
  }
}

# Application для демонстрації GitOps
resource "kubernetes_manifest" "demo_application" {
  count = var.create_demo_application ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "demo-app"
      namespace = kubernetes_namespace.argocd.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = "demo-app"
        "app.kubernetes.io/instance" = var.release_name
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.demo_app_repo_url
        targetRevision = var.demo_app_target_revision
        path           = var.demo_app_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.demo_app_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd]
}

# AppProject для організації додатків
resource "kubernetes_manifest" "app_project" {
  count = var.create_app_project ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = var.app_project_name
      namespace = kubernetes_namespace.argocd.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = var.app_project_name
        "app.kubernetes.io/instance" = var.release_name
      }
    }
    spec = {
      description = "Application project for ${var.app_project_name}"
      
      sourceRepos = var.app_project_source_repos
      
      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]
      
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      
      namespaceResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      
      roles = [
        {
          name = "admin"
          policies = [
            "p, proj:${var.app_project_name}:admin, applications, *, ${var.app_project_name}/*, allow",
            "p, proj:${var.app_project_name}:admin, repositories, *, *, allow"
          ]
          groups = var.app_project_admin_groups
        },
        {
          name = "developer"
          policies = [
            "p, proj:${var.app_project_name}:developer, applications, get, ${var.app_project_name}/*, allow",
            "p, proj:${var.app_project_name}:developer, applications, sync, ${var.app_project_name}/*, allow"
          ]
          groups = var.app_project_developer_groups
        }
      ]
    }
  }

  depends_on = [helm_release.argocd]
}