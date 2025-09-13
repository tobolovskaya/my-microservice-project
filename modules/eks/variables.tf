# Змінні для EKS модуля

# Основні параметри кластера
variable "cluster_name" {
  description = "Назва EKS кластера"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Назва кластера повинна починатися з літери та містити тільки літери, цифри та дефіси."
  }
}

variable "kubernetes_version" {
  description = "Версія Kubernetes"
  type        = string
  default     = "1.28"
  
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Версія Kubernetes повинна бути у форматі X.Y (наприклад, 1.28)."
  }
}

# Мережеві параметри
variable "vpc_id" {
  description = "ID VPC для EKS кластера"
  type        = string
}

variable "subnet_ids" {
  description = "Список ID підмереж для EKS кластера"
  type        = list(string)
  
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Потрібно мінімум 2 підмережі для EKS кластера."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR блоки, яким дозволено доступ до API сервера"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Налаштування endpoint
variable "endpoint_private_access" {
  description = "Увімкнути приватний доступ до API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Увімкнути публічний доступ до API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR блоки для публічного доступу до API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Логування
variable "cluster_log_types" {
  description = "Типи логів для увімкнення в CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  validation {
    condition = alltrue([
      for log_type in var.cluster_log_types : contains([
        "api", "audit", "authenticator", "controllerManager", "scheduler"
      ], log_type)
    ])
    error_message = "Дозволені типи логів: api, audit, authenticator, controllerManager, scheduler."
  }
}

# Шифрування
variable "cluster_encryption_config_enabled" {
  description = "Увімкнути шифрування секретів в etcd"
  type        = bool
  default     = true
}

variable "cluster_encryption_config_kms_key_id" {
  description = "ARN KMS ключа для шифрування секретів"
  type        = string
  default     = ""
}

# Node Groups конфігурація
variable "node_groups" {
  description = "Конфігурація node groups"
  type = list(object({
    name                         = string
    instance_types              = list(string)
    ami_type                    = string
    capacity_type               = string
    desired_size                = number
    max_size                    = number
    min_size                    = number
    max_unavailable_percentage  = number
    disk_size                   = number
    disk_type                   = string
    subnet_ids                  = list(string)
    labels                      = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    bootstrap_extra_args = string
  }))
  
  default = [
    {
      name                        = "main"
      instance_types             = ["t3.medium"]
      ami_type                   = "AL2_x86_64"
      capacity_type              = "ON_DEMAND"
      desired_size               = 2
      max_size                   = 4
      min_size                   = 1
      max_unavailable_percentage = 25
      disk_size                  = 50
      disk_type                  = "gp3"
      subnet_ids                 = []
      labels                     = {}
      taints                     = []
      bootstrap_extra_args       = ""
    }
  ]
  
  validation {
    condition = alltrue([
      for ng in var.node_groups : ng.min_size <= ng.desired_size && ng.desired_size <= ng.max_size
    ])
    error_message = "Для кожної node group: min_size <= desired_size <= max_size."
  }
  
  validation {
    condition = alltrue([
      for ng in var.node_groups : contains([
        "AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64"
      ], ng.ami_type)
    ])
    error_message = "AMI type повинен бути одним з підтримуваних типів."
  }
  
  validation {
    condition = alltrue([
      for ng in var.node_groups : contains(["ON_DEMAND", "SPOT"], ng.capacity_type)
    ])
    error_message = "Capacity type повинен бути ON_DEMAND або SPOT."
  }
}

# EBS CSI Driver налаштування
variable "enable_ebs_csi_driver" {
  description = "Увімкнути AWS EBS CSI Driver"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = "Версія EBS CSI Driver addon"
  type        = string
  default     = null
}

variable "ebs_csi_kms_key_id" {
  description = "ARN KMS ключа для шифрування EBS томів"
  type        = string
  default     = ""
}

variable "create_storage_classes" {
  description = "Створити storage classes для EBS CSI Driver"
  type        = bool
  default     = true
}

variable "set_gp3_as_default_storage_class" {
  description = "Встановити gp3 як default storage class"
  type        = bool
  default     = true
}

variable "remove_default_gp2_storage_class" {
  description = "Видалити default annotation з gp2 storage class"
  type        = bool
  default     = true
}

# Додаткові add-ons
variable "enable_vpc_cni_addon" {
  description = "Увімкнути VPC CNI addon"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Версія VPC CNI addon"
  type        = string
  default     = null
}

variable "enable_coredns_addon" {
  description = "Увімкнути CoreDNS addon"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "Версія CoreDNS addon"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "Увімкнути kube-proxy addon"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "Версія kube-proxy addon"
  type        = string
  default     = null
}

# Теги
variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "eks"
  }
}