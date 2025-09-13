# Створення S3-бакета для зберігання стану Terraform

# S3 бакет для стану Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name        = var.bucket_name
    Purpose     = "Terraform State Storage"
    Environment = var.environment
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Налаштування версіонування
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Налаштування шифрування
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Блокування публічного доступу
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Політика бакета для додаткової безпеки
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.terraform_state]
}

# Налаштування lifecycle для очищення старих версій
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    # Видалення неповних multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Зберігання старих версій
    noncurrent_version_expiration {
      noncurrent_days = var.state_retention_days
    }

    # Переведення старих версій в IA storage class
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # Переведення старих версій в Glacier
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }
  }
}

# Налаштування логування доступу (опціонально)
resource "aws_s3_bucket" "access_logs" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = "${var.bucket_name}-access-logs"

  tags = merge(var.tags, {
    Name        = "${var.bucket_name}-access-logs"
    Purpose     = "S3 Access Logs"
    Environment = var.environment
  })
}

resource "aws_s3_bucket_logging" "terraform_state" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "access-logs/"
}