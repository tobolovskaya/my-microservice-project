# Після створення S3 + DynamoDB розкоментуй:

terraform 
backend "s3" {
bucket         = "var.backend_bucket_name"     # те ж саме, що backend_bucket_name
key            = "lesson-5/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "terraform-locks"
encrypt        = true
  }
