terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.bucket_name
  table_name  = "terraform-locks-lesson8-9"
  aws_region  = var.aws_region
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-8-9-vpc"
}

# Підключаємо модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-8-9-django-app"
  scan_on_push = true
}

# Підключаємо модуль EKS
module "eks" {
  source = "./modules/eks"
  
  cluster_name    = "lesson-8-9-eks-cluster"
  cluster_version = "1.28"
  
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  
  node_groups = {
    main = {
      desired_size = 3
      max_size     = 6
      min_size     = 2
      
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      
      k8s_labels = {
        Environment = "lesson-8-9"
        NodeGroup   = "main"
      }
    }
  }
}

# Підключаємо модуль Jenkins
module "jenkins" {
  source = "./modules/jenkins"
  
  cluster_name     = module.eks.cluster_id
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_cert  = module.eks.cluster_certificate_authority_data
  
  jenkins_namespace = "jenkins"
  jenkins_version   = "4.8.3"
  
  # ECR та AWS налаштування для Jenkins
  ecr_repository_url = module.ecr.repository_url
  aws_region        = var.aws_region
  
  depends_on = [module.eks]
}

# Підключаємо модуль Argo CD
module "argo_cd" {
  source = "./modules/argo_cd"
  
  cluster_name     = module.eks.cluster_id
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_cert  = module.eks.cluster_certificate_authority_data
  
  argocd_namespace = "argocd"
  argocd_version   = "5.51.6"
  
  # Git repository для Helm charts
  git_repository_url = var.git_repository_url
  
  depends_on = [module.eks]
}