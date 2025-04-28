output "s3_bucket_url" {
  description = "The S3_BUCKET_URL environment variable for the app."
  value = "https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.storage.bucket}"
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
