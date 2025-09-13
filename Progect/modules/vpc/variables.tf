# Змінні для VPC

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR повинен бути валідним CIDR блоком."
  }
}

variable "availability_zones" {
  description = "Список зон доступності"
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Потрібно мінімум 2 зони доступності."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR блоки для публічних підмереж"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Потрібно мінімум 2 публічні підмережі."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR блоки для приватних підмереж"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "Потрібно мінімум 2 приватні підмережі."
  }
}

variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default     = {}
}