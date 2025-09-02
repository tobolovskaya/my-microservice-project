resource "aws_ecr_repository" "this" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = var.tags
}

# Приклад простої політики (доступ лише вашому акаунту; за потреби додай інші principals)
data "aws_caller_identity" "current" {}

resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [{
      Sid       = "AllowAccountPushPull",
      Effect    = "Allow",
      Principal = { AWS = data.aws_caller_identity.current.account_id },
      Action    = ["ecr:*"]
    }]
  })
}
