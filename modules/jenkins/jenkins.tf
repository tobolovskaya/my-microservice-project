# Jenkins Helm Release модуль

# Namespace для Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# Secret для Jenkins admin password
resource "kubernetes_secret" "jenkins_admin" {
  metadata {
    name      = "jenkins-admin-secret"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    jenkins-admin-password = var.admin_password
  }

  type = "Opaque"
}

# PersistentVolumeClaim для Jenkins home
resource "kubernetes_persistent_volume_claim" "jenkins_home" {
  count = var.create_pvc ? 1 : 0

  metadata {
    name      = "jenkins-home-pvc"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    
    storage_class_name = var.storage_class
  }

  wait_until_bound = true
}

# ServiceAccount для Jenkins з необхідними правами
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins-serviceaccount"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  automount_service_account_token = true
}

# ClusterRole для Jenkins
resource "kubernetes_cluster_role" "jenkins" {
  metadata {
    name = "jenkins-clusterrole"
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec", "pods/log", "persistentvolumeclaims", "events"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets", "configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

# ClusterRoleBinding для Jenkins
resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins-clusterrolebinding"
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.jenkins.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.jenkins.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

# ConfigMap для додаткових Jenkins конфігурацій
resource "kubernetes_config_map" "jenkins_config" {
  count = length(var.jenkins_config_files) > 0 ? 1 : 0

  metadata {
    name      = "jenkins-config"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  data = var.jenkins_config_files
}

# Helm Release для Jenkins
resource "helm_release" "jenkins" {
  name       = var.release_name
  repository = var.helm_repository
  chart      = var.helm_chart
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  # Використання values.yaml файлу
  values = [
    file("${path.module}/values.yaml"),
    var.additional_values
  ]

  # Динамічні значення
  set {
    name  = "controller.adminPassword"
    value = var.admin_password
  }

  set {
    name  = "controller.adminUser"
    value = var.admin_user
  }

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = kubernetes_service_account.jenkins.metadata[0].name
  }

  set {
    name  = "persistence.enabled"
    value = var.persistence_enabled
  }

  set {
    name  = "persistence.size"
    value = var.storage_size
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "persistence.existingClaim"
    value = var.create_pvc ? kubernetes_persistent_volume_claim.jenkins_home[0].metadata[0].name : ""
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = var.resources.requests.cpu
  }

  set {
    name  = "controller.resources.requests.memory"
    value = var.resources.requests.memory
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = var.resources.limits.cpu
  }

  set {
    name  = "controller.resources.limits.memory"
    value = var.resources.limits.memory
  }

  set {
    name  = "controller.ingress.enabled"
    value = var.ingress_enabled
  }

  set {
    name  = "controller.ingress.hostName"
    value = var.ingress_hostname
  }

  set {
    name  = "controller.ingress.ingressClassName"
    value = var.ingress_class_name
  }

  set {
    name  = "controller.serviceType"
    value = var.service_type
  }

  # Додаткові налаштування для AWS
  dynamic "set" {
    for_each = var.aws_region != "" ? [1] : []
    content {
      name  = "controller.javaOpts"
      value = "-Daws.region=${var.aws_region}"
    }
  }

  # Налаштування для ECR
  dynamic "set" {
    for_each = var.ecr_registry_url != "" ? [1] : []
    content {
      name  = "controller.initContainerEnv[0].name"
      value = "ECR_REGISTRY_URL"
    }
  }

  dynamic "set" {
    for_each = var.ecr_registry_url != "" ? [1] : []
    content {
      name  = "controller.initContainerEnv[0].value"
      value = var.ecr_registry_url
    }
  }

  # Налаштування безпеки
  set {
    name  = "controller.runAsUser"
    value = "1000"
  }

  set {
    name  = "controller.fsGroup"
    value = "1000"
  }

  # Налаштування для plugins
  dynamic "set" {
    for_each = var.install_plugins
    content {
      name  = "controller.installPlugins[${set.key}]"
      value = set.value
    }
  }

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_service_account.jenkins,
    kubernetes_cluster_role_binding.jenkins,
    kubernetes_secret.jenkins_admin
  ]

  timeout = var.helm_timeout

  # Очікування готовності
  wait          = true
  wait_for_jobs = true
}

# Service для доступу до Jenkins (якщо потрібен LoadBalancer)
resource "kubernetes_service" "jenkins_lb" {
  count = var.service_type == "LoadBalancer" && var.create_load_balancer_service ? 1 : 0

  metadata {
    name      = "${var.release_name}-loadbalancer"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
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

    selector = {
      "app.kubernetes.io/component" = "jenkins-controller"
      "app.kubernetes.io/instance"  = var.release_name
    }

    load_balancer_source_ranges = var.load_balancer_source_ranges
  }
}

# Ingress для Jenkins (якщо увімкнено)
resource "kubernetes_ingress_v1" "jenkins" {
  count = var.ingress_enabled && var.create_custom_ingress ? 1 : 0

  metadata {
    name      = "${var.release_name}-ingress"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
    annotations = merge(
      {
        "kubernetes.io/ingress.class" = var.ingress_class_name
        "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
        "nginx.ingress.kubernetes.io/proxy-request-buffering" = "off"
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
              name = "${var.release_name}-jenkins"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

# HorizontalPodAutoscaler для Jenkins (опціонально)
resource "kubernetes_horizontal_pod_autoscaler_v2" "jenkins" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "${var.release_name}-hpa"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "jenkins"
      "app.kubernetes.io/instance" = var.release_name
    }
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "${var.release_name}-jenkins"
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