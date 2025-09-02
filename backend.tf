# backend.tf (у корені)
terraform {
  # Конфіг бекенду задаватимемо під час init через -backend-config
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Провайдер
provider "aws" {
  region = var.region
}

