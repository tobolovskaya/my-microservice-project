@@ .. @@
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
+
+# Підключаємо модуль RDS
+module "rds" {
+  source = "./modules/rds"
+  
+  # Основні налаштування
+  use_aurora   = var.use_aurora
+  engine       = var.db_engine
+  engine_version = var.db_engine_version
+  instance_class = var.db_instance_class
+  
+  # База даних
+  db_name  = var.db_name
+  username = var.db_username
+  password = var.db_password
+  
+  # Мережа
+  vpc_id     = module.vpc.vpc_id
+  subnet_ids = module.vpc.private_subnet_ids
+  
+  # Безпека
+  allowed_cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
+  
+  # Aurora налаштування
+  aurora_cluster_instances = var.aurora_cluster_instances
+  aurora_instance_class   = var.aurora_instance_class
+  
+  # Загальні налаштування
+  multi_az               = var.db_multi_az
+  backup_retention_period = var.db_backup_retention_period
+  deletion_protection    = var.db_deletion_protection
+  storage_encrypted      = true
+  
+  # Теги
+  project_name = "lesson-8-9"
+  environment  = "dev"
+  
+  tags = {
+    Project     = "lesson-8-9"
+    Environment = "dev"
+    Component   = "Database"
+  }
+  
+  depends_on = [module.vpc]
+}