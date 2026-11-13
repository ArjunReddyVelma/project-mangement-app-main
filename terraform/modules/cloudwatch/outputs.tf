output "dashboard_log_group_name" {
  description = "Name of the application CloudWatch log group."
  value       = aws_cloudwatch_log_group.dashboard.name
}

output "eks_cluster_log_group_name" {
  description = "Name of the EKS cluster CloudWatch log group."
  value       = aws_cloudwatch_log_group.eks_cluster.name
}
