output "ecr_repository_url" {
  description = "Tag and push the dashboard image to this ECR repository."
  value       = module.ecr.repository_url
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for dashboard logs."
  value       = module.cloudwatch.dashboard_log_group_name
}

output "vpc_id" {
  description = "VPC ID where the infrastructure is deployed."
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Name of the provisioned EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint for the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "github_actions_role_arn" {
  description = "OIDC Deployer role ARN for GitHub Actions."
  value       = module.iam.github_actions_role_arn
}
