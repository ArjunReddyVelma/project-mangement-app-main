variable "aws_region" {
  type        = string
  description = "AWS region for the container registry and log group."
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  default     = "project-management"
}

variable "environment" {
  type        = string
  default     = "dev"
}
