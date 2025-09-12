terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-lesson5"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}