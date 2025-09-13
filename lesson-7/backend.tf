terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-lesson7"
    key            = "lesson-7/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-lesson7"
    encrypt        = true
  }
}