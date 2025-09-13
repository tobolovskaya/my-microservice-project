terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-lesson8-9"
    key            = "lesson-8-9/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-lesson8-9"
    encrypt        = true
  }
}