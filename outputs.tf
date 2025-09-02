output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "ecr_repository_url" { value = module.ecr.repository_url }
output "state_bucket_name" { value = module.s3_backend.bucket_name }
output "locks_table_name" { value = module.s3_backend.dynamodb_table_name }
