output "ecr_repository_url" {
  description = "ECR repository URL for Docker image push"
  value       = aws_ecr_repository.self_healing.repository_url
}
