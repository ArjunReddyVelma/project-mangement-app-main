output "repository_url" {
  description = "Tag and push the dashboard image to this ECR repository."
  value       = aws_ecr_repository.dashboard.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.dashboard.arn
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.dashboard.name
}
