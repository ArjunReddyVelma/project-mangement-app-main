variable "project_name" {
  type        = string
  description = "Project name used for tagging and resource naming."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository owner/name for OIDC trust."
  default     = "ArjunReddyVelma/project-mangement-app-main"
}
