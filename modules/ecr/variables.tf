# Змінні для ECR модуля

# Основні параметри
variable "repository_name" {
  description = "Назва ECR репозиторію"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9._-]*[a-z0-9])?$", var.repository_name))
    error_message = "Назва репозиторію повинна містити тільки малі літери, цифри, крапки, дефіси та підкреслення."
  }
}

variable "image_tag_mutability" {
  description = "Можливість змінювати теги образів (MUTABLE або IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability повинен бути MUTABLE або IMMUTABLE."
  }
}

# Налаштування сканування
variable "scan_on_push" {
  description = "Сканувати образи при завантаженні"
  type        = bool
  default     = true
}

variable "enable_registry_scanning" {
  description = "Увімкнути розширене сканування реєстру"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Тип сканування реєстру (BASIC або ENHANCED)"
  type        = string
  default     = "BASIC"
  
  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.registry_scan_type)
    error_message = "Registry scan type повинен бути BASIC або ENHANCED."
  }
}

variable "registry_scan_filters" {
  description = "Фільтри для сканування реєстру"
  type = list(object({
    filter          = string
    filter_type     = string
    scan_frequency  = string
  }))
  default = []
}

# Шифрування
variable "encryption_type" {
  description = "Тип шифрування (AES256 або KMS)"
  type        = string
  default     = "AES256"
  
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type повинен бути AES256 або KMS."
  }
}

variable "kms_key" {
  description = "ARN KMS ключа для шифрування (тільки для KMS типу)"
  type        = string
  default     = null
}

# Політика життєвого циклу
variable "enable_lifecycle_policy" {
  description = "Увімкнути політику життєвого циклу"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Максимальна кількість образів для зберігання"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_image_count > 0 && var.max_image_count <= 1000
    error_message = "Максимальна кількість образів повинна бути від 1 до 1000."
  }
}

variable "untagged_image_days" {
  description = "Кількість днів для зберігання образів без тегів"
  type        = number
  default     = 1
  
  validation {
    condition     = var.untagged_image_days >= 1 && var.untagged_image_days <= 365
    error_message = "Кількість днів повинна бути від 1 до 365."
  }
}

variable "lifecycle_tag_prefixes" {
  description = "Префікси тегів для політики життєвого циклу"
  type        = list(string)
  default     = ["v", "release", "latest"]
}

# Міжакаунтний доступ
variable "enable_cross_account_access" {
  description = "Увімкнути міжакаунтний доступ"
  type        = bool
  default     = false
}

variable "cross_account_arns" {
  description = "ARN акаунтів для міжакаунтного доступу"
  type        = list(string)
  default     = []
}

# Реплікація
variable "replication_regions" {
  description = "Регіони для реплікації"
  type = list(object({
    region      = string
    registry_id = string
  }))
  default = []
}

# Теги
variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Module    = "ecr"
  }
}

# Додаткові налаштування
variable "force_delete" {
  description = "Примусово видалити репозиторій навіть якщо він містить образи"
  type        = bool
  default     = false
}