@@ .. @@
 output "argocd_admin_password_command" {
   description = "Command to get Argo CD admin password"
   value       = module.argo_cd.admin_password_command
 }
 
+# Database outputs
+output "database_type" {
+  description = "Type of database created"
+  value       = var.use_aurora ? "Aurora Cluster" : "RDS Instance"
+}
+
+output "database_endpoint" {
+  description = "Database endpoint"
+  value       = var.use_aurora ? module.rds.aurora_cluster_endpoint : module.rds.rds_instance_endpoint
+}
+
+output "database_port" {
+  description = "Database port"
+  value       = module.rds.port
+}
+
+output "database_connection_info" {
+  description = "Database connection information"
+  value       = module.rds.connection_info
+  sensitive   = false
+}
+
+output "database_summary" {
+  description = "Summary of the created database resources"
+  value       = module.rds.database_summary
+}
+
 # Useful commands
 output "useful_commands" {
   description = "Useful commands for managing the infrastructure"
   value = {
     kubectl_config    = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_id}"
     jenkins_password  = module.jenkins.admin_password_command
     argocd_password   = module.argo_cd.admin_password_command
     jenkins_url       = module.jenkins.jenkins_url
     argocd_url        = module.argo_cd.argocd_url
+    database_endpoint = var.use_aurora ? module.rds.aurora_cluster_endpoint : module.rds.rds_instance_endpoint
   }
 }