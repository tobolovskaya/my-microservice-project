# Створення ECR репозиторію

resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  # Налаштування сканування образів
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  # Шифрування
  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key        = var.encryption_type == "KMS" ? var.kms_key : null
  }

  tags = merge(var.tags, {
    Name = var.repository_name
  })
}

# Політика життєвого циклу для управління образами
resource "aws_ecr_lifecycle_policy" "main" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.lifecycle_tag_prefixes
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Політика репозиторію для контролю доступу
resource "aws_ecr_repository_policy" "main" {
  count      = var.enable_cross_account_access ? 1 : 0
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.cross_account_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchDeleteImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
      }
    ]
  })
}

# Реплікація в інші регіони (опціонально)
resource "aws_ecr_replication_configuration" "main" {
  count = length(var.replication_regions) > 0 ? 1 : 0

  replication_configuration {
    dynamic "rule" {
      for_each = var.replication_regions
      content {
        destination {
          region      = rule.value.region
          registry_id = rule.value.registry_id
        }
        repository_filter {
          filter      = var.repository_name
          filter_type = "PREFIX_MATCH"
        }
      }
    }
  }
}

# Registry scanning configuration (якщо потрібно)
resource "aws_ecr_registry_scanning_configuration" "main" {
  count       = var.enable_registry_scanning ? 1 : 0
  scan_type   = var.registry_scan_type
  
  dynamic "rule" {
    for_each = var.registry_scan_filters
    content {
      scan_frequency = rule.value.scan_frequency
      repository_filter {
        filter      = rule.value.filter
        filter_type = rule.value.filter_type
      }
    }
  }
}