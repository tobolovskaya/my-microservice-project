variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "my-terraform-state-bucket-lesson8-9"
}

variable "git_repository_url" {
  description = "Git repository URL for Argo CD applications"
  type        = string
  default     = "https://github.com/your-username/your-repo.git"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lesson-8-9"
}