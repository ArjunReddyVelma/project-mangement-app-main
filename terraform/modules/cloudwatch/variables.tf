variable "project_name" {
  type        = string
  description = "Project name used for naming CloudWatch log groups."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain logs in CloudWatch."
  default     = 14
}
