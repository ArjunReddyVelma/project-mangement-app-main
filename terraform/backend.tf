# -------------------------------------------------------------
# Terraform Remote State & Locking Configuration
# -------------------------------------------------------------
# For production state management, configure remote S3 backend
# with server-side encryption and DynamoDB state locking.
#
# terraform {
#   backend "s3" {
#     bucket         = "project-management-terraform-state"
#     key            = "devops-platform/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "project-management-terraform-locks"
#     encrypt        = true
#   }
# }
