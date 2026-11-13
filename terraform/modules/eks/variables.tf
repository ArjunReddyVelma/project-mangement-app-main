variable "project_name" {
  type        = string
  description = "Project name used for naming EKS resources."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster."
  default     = "1.31"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS will be provisioned."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC for security group egress filtering."
  default     = "10.0.0.0/16"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for EKS control plane and node groups."
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM Role ARN for the EKS cluster."
}

variable "node_role_arn" {
  type        = string
  description = "IAM Role ARN for the EKS worker nodes."
}

variable "github_actions_role_arn" {
  type        = string
  description = "IAM Role ARN of the GitHub Actions CD deployer for cluster access."
}

variable "instance_types" {
  type        = list(string)
  description = "EC2 instance types for the node group."
  default     = ["t3.medium"]
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes."
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes."
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes."
  default     = 5
}
