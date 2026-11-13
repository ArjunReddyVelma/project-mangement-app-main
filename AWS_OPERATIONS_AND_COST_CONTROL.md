# AWS Operations, Cost Control & Financial Governance Guide

## 1. Executive Summary

This operational guide establishes the financial governance policies, automated budget alerts, cost allocation tagging taxonomy, and decommissioning procedures for the **Project Management Dashboard DevOps Platform** on Amazon Web Services (**AWS**).

### Financial Status
- **Actual Accrued AWS Spend to Date:** **$0.00** (Zero billable cloud resources provisioned; all infrastructure strictly managed under Phase 3 & Phase 4 safety gates).
- **Estimated Baseline Monthly Run Rate:** **$176.94 / month** (in region `ap-south-1`).
- **Target Spot-Optimized Run Rate:** **$134.45 / month** (saving $42.49/mo).

---

## 2. Mandatory Cost Allocation Tagging Taxonomy

All cloud infrastructure provisioned via Terraform must enforce the following standardized tags:

| Tag Key | Example Value | Enforcement Purpose |
| :--- | :--- | :--- |
| `Project` | `project-management` | Groups all related infrastructure across AWS Cost Explorer. |
| `Environment` | `dev` / `staging` / `prod` | Enables granular per-environment cost allocation. |
| `ManagedBy` | `Terraform` | Differentiates automated IaC resources from manual console drift. |
| `Owner` | `DevOps-Platform-Team` | Identifies responsible engineering team for billing accountability. |
| `CostCenter` | `Engineering-Core-104` | Maps AWS expenses to corporate financial cost centers. |

Terraform provider configuration automatically injects these default tags across all resources:
```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "project-management"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
      CostCenter  = "Core-DevOps"
    }
  }
}
```

---

## 3. Automated AWS Budget & Anomaly Detection

To prevent accidental cost overruns, an automated AWS Budget is configured to track monthly spend with threshold alerts:

```hcl
# terraform/budget.tf
resource "aws_budgets_budget" "monthly_devops_budget" {
  name              = "project-management-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "200"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  cost_filter {
    name   = "TagKeyValue"
    values = ["Project$project-management"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["devops-alerts@example.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["devops-lead@example.com"]
  }
}
```

---

## 4. Resource Retention & Storage Lifecycle Policies

### Amazon ECR Lifecycle Policy (Enforced)
- **Problem:** Unmanaged container registries accumulate hundreds of gigabytes of stale images over time, incurring silent storage fees ($0.10/GB/month).
- **Enforced Policy:** Configured in `terraform/modules/ecr/main.tf`, keeping only the **10 most recent images** and automatically expiring older untagged or stale revisions.
- **Monthly Storage Cap:** ~500MB total storage (< $0.05/month).

### CloudWatch Log Retention Policy (Enforced)
- **Problem:** Default CloudWatch log groups retain log streams indefinitely, creating compounding storage costs.
- **Enforced Policy:** Configured in `terraform/modules/cloudwatch/main.tf`, enforcing an explicit **14-day retention window** (`retention_in_days = 14`). Older logs are purged automatically.

---

## 5. Compute & Network Cost Optimization Opportunities

### 1. Spot Instance Worker Nodes (Development / Staging)
- **On-Demand Baseline:** 2 × `t3.medium` @ $0.0416/hr = **$60.74/month**.
- **Spot Optimization:** Configuring `capacity_type = "SPOT"` yields an average pricing of ~$0.0125/hr in `ap-south-1`.
- **Monthly Spot Cost:** **$18.25/month** (Savings: **$42.49/month** or 70%).

### 2. Single NAT Gateway vs. Multi-AZ NAT
- **Multi-AZ Architecture:** 1 NAT Gateway per AZ (2 AZs) = 2 × $32.85 = **$65.70/month**.
- **Current Architecture:** 1 Shared NAT Gateway in AZ `ap-south-1a` = **$32.85/month**.
- **Trade-Off Analysis:** Saves **$32.85/month** during non-production and development operations with minimal failure probability for development environments.

### 3. Automated Off-Hours Cluster Scheduling
- Development clusters do not require 24/7 compute.
- Scaling node groups to 0 replicas between 8:00 PM and 8:00 AM weekdays and all weekend days (160 active hours/month):
  - EC2 Compute: Drops from $60.74 to **$13.31/month**.
  - Total environment cost reduced from $176.94 to **~$95.00/month**.

---

## 6. Comprehensive Teardown Procedure

To immediately eliminate 100% of recurring cloud expenses, follow this exact reverse-order decommissioning sequence:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Initiating complete DevOps platform decommissioning..."

# Step 1: Remove Kubernetes workloads (deregisters ALBs and target groups)
if kubectl get namespace project-dashboard &>/dev/null; then
  echo "Deleting Kubernetes workloads in namespace project-dashboard..."
  kubectl delete -f k8s/project-dashboard.yaml --ignore-not-found=true
  kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
fi

# Step 2: Empty Amazon ECR repository (prevents destroy failure due to existing images)
REPO_NAME="project-management-dashboard"
if aws ecr describe-repositories --repository-names "$REPO_NAME" --region ap-south-1 &>/dev/null; then
  echo "Purging images from Amazon ECR repository $REPO_NAME..."
  IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO_NAME" --region ap-south-1 --query 'imageIds[*]' --output json)
  if [ "$IMAGE_IDS" != "[]" ]; then
    aws ecr batch-delete-image --repository-name "$REPO_NAME" --image-ids "$IMAGE_IDS" --region ap-south-1
  fi
fi

# Step 3: Destroy Terraform managed infrastructure
echo "Executing Terraform destroy..."
cd terraform
terraform destroy -auto-approve

# Step 4: Decommission remote state S3 bucket & DynamoDB table (if terminating project)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="project-management-terraform-state-${ACCOUNT_ID}-ap-south-1"

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Deleting remote state bucket $BUCKET_NAME..."
  aws s3 rb "s3://${BUCKET_NAME}" --force
fi

if aws dynamodb describe-table --table-name project-management-terraform-locks --region ap-south-1 &>/dev/null; then
  echo "Deleting DynamoDB lock table..."
  aws dynamodb delete-table --table-name project-management-terraform-locks --region ap-south-1
fi

echo "Teardown complete. All AWS billable resources eliminated."
```

---

## 7. Operational Accountability

- **Platform Technical Owner:** Senior DevOps / SRE Lead
- **Escalation Path:** Architecture Review Board → DevOps Lead → Security Team
- **Financial Review Cadence:** Monthly AWS Cost Explorer review on the 1st of every month.