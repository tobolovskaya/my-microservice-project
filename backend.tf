# Налаштування бекенду для стейтів (S3 + DynamoDB)
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-unique-name"
    key            = "terraform/state"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}