output "ecr_repository_url" {
  description = "ECR repository URL for Docker image push"
  value       = aws_ecr_repository.self_healing.repository_url
}

output "ecr_image" {
  value = local.ecr_image
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "log_group" {
  value = aws_cloudwatch_log_group.app.name
}
