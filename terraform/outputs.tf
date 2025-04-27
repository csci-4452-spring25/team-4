output "database_url" {
  description = "The DATABASE_URL environment variable for the app."
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}

output "redis_url" {
  description = "The REDIS_URL environment variable for the app."
  value       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
  sensitive   = true
}

output "s3_bucket_url" {
  description = "The S3_BUCKET_URL environment variable for the app."
  value       = aws_s3_bucket.storage.bucket
}

output "aws_ecr_repository" {
  description = "The name of the ECR repository."
  value       = aws_ecr_repository.app.name
}

output "aws_ecr_registry" {
  description = "The registry URL for the ECR repository."
  value       = aws_ecr_repository.app.repository_url
}

output "aws_ecs_service" {
  description = "The name of the ECS service."
  value       = aws_ecs_service.app.name
}

output "aws_ecs_cluster" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "aws_task_def_arn" {
  description = "The ARN of the ECS task definition."
  value       = aws_ecs_task_definition.app.arn
}
