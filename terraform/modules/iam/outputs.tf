output "cluster_role_arn" {
  description = "ARN of the EKS Cluster IAM role."
  value       = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  description = "ARN of the EKS Node Group IAM role."
  value       = aws_iam_role.eks_nodes.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions OIDC deployment."
  value       = aws_iam_role.github_actions_cd.arn
}
