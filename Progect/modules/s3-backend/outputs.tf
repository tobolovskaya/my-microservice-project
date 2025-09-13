# Виведення інформації про S3 та DynamoDB

# S3 виводи
output "s3_bucket_id" {
  description = "ID S3 бакета"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN S3 бакета"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name S3 бакета"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name S3 бакета"
  value       = aws_s3_bucket.terraform_state.bucket_regional_domain_name
}

output "s3_bucket_region" {
  description = "Регіон S3 бакета"
  value       = aws_s3_bucket.terraform_state.region
}

# DynamoDB виводи
output "dynamodb_table_id" {
  description = "ID DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_state_lock.id
}

output "dynamodb_table_arn" {
  description = "ARN DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "dynamodb_table_name" {
  description = "Назва DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "dynamodb_table_stream_arn" {
  description = "ARN DynamoDB stream (якщо увімкнено)"
  value       = aws_dynamodb_table.terraform_state_lock.stream_arn
}

# Конфігурація для backend
output "terraform_backend_config" {
  description = "Конфігурація для terraform backend"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "terraform/state"
    region         = aws_s3_bucket.terraform_state.region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    encrypt        = true
  }
}

# Готовий блок backend для копіювання
output "backend_configuration" {
  description = "Готова конфігурація backend для вставки в terraform блок"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "terraform/state"
        region         = "${aws_s3_bucket.terraform_state.region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
        encrypt        = true
      }
    }
  EOT
}

# Логування (якщо увімкнено)
output "access_logs_bucket_id" {
  description = "ID бакета для логів доступу"
  value       = var.enable_access_logging ? aws_s3_bucket.access_logs[0].id : null
}

# Auto Scaling виводи
output "autoscaling_read_target_arn" {
  description = "ARN цілі автоскейлінгу для читання"
  value       = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? aws_appautoscaling_target.dynamodb_table_read_target[0].arn : null
}

output "autoscaling_write_target_arn" {
  description = "ARN цілі автоскейлінгу для запису"
  value       = var.dynamodb_billing_mode == "PROVISIONED" && var.enable_dynamodb_autoscaling ? aws_appautoscaling_target.dynamodb_table_write_target[0].arn : null
}

# CloudWatch алерти
output "read_throttle_alarm_arn" {
  description = "ARN алерту для read throttle"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.dynamodb_read_throttle[0].arn : null
}

output "write_throttle_alarm_arn" {
  description = "ARN алерту для write throttle"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.dynamodb_write_throttle[0].arn : null
}