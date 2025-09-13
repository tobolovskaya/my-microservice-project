@@ .. @@
 variable "environment" {
   description = "Environment name"
   type        = string
   default     = "lesson-8-9"
 }
+
+# Database variables
+variable "use_aurora" {
+  description = "Whether to use Aurora cluster (true) or regular RDS instance (false)"
+  type        = bool
+  default     = false
+}
+
+variable "db_engine" {
+  description = "Database engine (mysql, postgres, aurora-mysql, aurora-postgresql)"
+  type        = string
+  default     = "postgres"
+}
+
+variable "db_engine_version" {
+  description = "Database engine version"
+  type        = string
+  default     = ""
+}
+
+variable "db_instance_class" {
+  description = "Database instance class"
+  type        = string
+  default     = "db.t3.micro"
+}
+
+variable "db_name" {
+  description = "Name of the database"
+  type        = string
+  default     = "mydb"
+}
+
+variable "db_username" {
+  description = "Master username"
+  type        = string
+  default     = "admin"
+}
+
+variable "db_password" {
+  description = "Master password"
+  type        = string
+  sensitive   = true
+  default     = "changeme123!"
+}
+
+variable "aurora_cluster_instances" {
+  description = "Number of Aurora cluster instances"
+  type        = number
+  default     = 2
+}
+
+variable "aurora_instance_class" {
+  description = "Aurora instance class"
+  type        = string
+  default     = "db.r5.large"
+}
+
+variable "db_multi_az" {
+  description = "Whether to enable Multi-AZ deployment"
+  type        = bool
+  default     = false
+}
+
+variable "db_backup_retention_period" {
+  description = "Backup retention period in days"
+  type        = number
+  default     = 7
+}
+
+variable "db_deletion_protection" {
+  description = "Whether to enable deletion protection"
+  type        = bool
+  default     = false
+}