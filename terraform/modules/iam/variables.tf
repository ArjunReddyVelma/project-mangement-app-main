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

variable "github_branches" {
  type        = list(string)
  description = "Allowed Git branches for OIDC deployment."
  default     = ["main"]
}

variable "github_environments" {
  type        = list(string)
  description = "Allowed GitHub Environments for OIDC deployment."
  default     = ["production", "staging"]
}
