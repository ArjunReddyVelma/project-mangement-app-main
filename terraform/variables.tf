variable "aws_region" {
  type        = string
  description = "AWS region for the resources."
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  description = "Project name prefix."
  default     = "project-management"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, staging, prod)."
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository for OIDC federation."
  default     = "ArjunReddyVelma/project-mangement-app-main"
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days."
  default     = 14
}

variable "eks_desired_nodes" {
  type        = number
  description = "Desired number of worker nodes."
  default     = 2
}

variable "eks_min_nodes" {
  type        = number
  description = "Minimum number of worker nodes."
  default     = 2
}

variable "eks_max_nodes" {
  type        = number
  description = "Maximum number of worker nodes."
  default     = 5
}
