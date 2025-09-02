terraform {
  required_version = "~> 1.6"
}

# ---- Підключаємо модулі ----

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.backend_bucket_name # змінну оголошено нижче
  table_name  = "terraform-locks"
  tags = {
    Project = "lesson-5"
  }
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-5-vpc"
  single_nat_gateway = true # 1 NAT для економії. Постав false, якщо треба по NAT на AZ.
  tags = {
    Project = "lesson-5"
  }
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-5-ecr"
  scan_on_push = true
  tags = {
    Project     = "lesson-5"
    Environment = "dev"
  }
}