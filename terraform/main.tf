terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------------------------------------------
# Core Networking: VPC & Subnets
# -------------------------------------------------------------
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# -------------------------------------------------------------
# Identity & Access Management (IAM)
# -------------------------------------------------------------
module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  environment  = var.environment
  github_repo  = var.github_repo
}

# -------------------------------------------------------------
# Container Registry (ECR)
# -------------------------------------------------------------
module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}

# -------------------------------------------------------------
# Observability (CloudWatch)
# -------------------------------------------------------------
module "cloudwatch" {
  source            = "./modules/cloudwatch"
  project_name      = var.project_name
  environment       = var.environment
  retention_in_days = var.log_retention_days
}

# -------------------------------------------------------------
# Managed Kubernetes (EKS)
# -------------------------------------------------------------
module "eks" {
  source                  = "./modules/eks"
  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = module.vpc.vpc_cidr_block
  subnet_ids              = module.vpc.private_subnet_ids
  cluster_role_arn        = module.iam.cluster_role_arn
  node_role_arn           = module.iam.node_role_arn
  github_actions_role_arn = module.iam.github_actions_role_arn
  desired_size            = var.eks_desired_nodes
  min_size                = var.eks_min_nodes
  max_size                = var.eks_max_nodes
}
