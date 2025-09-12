output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for locks"
  value       = aws_dynamodb_table.terraform_locks.name
}