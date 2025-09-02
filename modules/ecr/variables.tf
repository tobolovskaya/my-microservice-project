variable "ecr_name" {
  type        = string
  description = "ECR repository name"
}

variable "scan_on_push" {
  type        = bool
  default     = true
  description = "Enable image scanning on push"
}
