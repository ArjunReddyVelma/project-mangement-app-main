# Cloud Infrastructure Cost Estimation & Optimization Guide

## 1. Executive Summary

This document details the estimated monthly operational costs for the **Project Management Dashboard DevOps Platform** on AWS in the **ap-south-1 (Mumbai)** region.

- **Estimated Monthly Baseline (Standard Development):** **$178.34 / month**
- **Estimated Cost with Spot Optimization:** **$135.80 / month**
- **Local Testing Environment (Kind):** **$0.00 / month**

---

## 2. Detailed Monthly Cost Breakdown

| AWS Service | Resource Specification | Pricing Unit | Monthly Cost (USD) |
| :--- | :--- | :--- | :--- |
| **Amazon EKS** | 1x EKS Cluster Control Plane | $0.10 / hour | $73.00 |
| **Amazon EC2 (Node Group)** | 2x `t3.medium` (2 vCPU, 4 GB RAM) | $0.0416 / hour per node | $60.74 |
| **Amazon EBS** | 2x 20 GB gp3 root volumes (40 GB total) | $0.08 / GB-month | $3.20 |
| **Amazon VPC** | 1x NAT Gateway (AZ-a) | $0.045 / hour | $32.85 |
| **NAT Data Processing** | ~100 GB outbound data transfer | $0.045 / GB | $4.50 |
| **AWS KMS** | 1x Customer Managed Key (EKS secrets) | $1.00 / key-month | $1.00 |
| **Amazon ECR** | 10 container images (~300 MB each = 3 GB) | $0.10 / GB-month | $0.30 |
| **Amazon CloudWatch** | Log ingestion (2 GB) + 14-day retention | $0.50 / GB + storage | $1.25 |
| **Amazon Route 53 & Data** | Public hosted zone + egress | Basic queries + egress | $1.50 |
| **Total Baseline Estimate** | | | **$178.34 / month** |

---

## 3. Cost Optimization Strategies

### Strategy 1: Spot Instances for Non-Production Node Groups
By utilizing Amazon EC2 Spot instances for the worker node group instead of On-Demand instances, compute costs can be reduced by up to **67%**:
- 2x `t3.medium` Spot: ~$0.0125/hr each -> **~$18.20/month** (Savings: **~$42.54/month**).

### Strategy 2: Single NAT Gateway in Non-Production
The VPC module provisions a single NAT Gateway shared across private subnets rather than a NAT Gateway per Availability Zone. This saves **~$37.35/month** per eliminated AZ.

### Strategy 3: Strict ECR Lifecycle Policy
The ECR repository is configured with an automated lifecycle policy keeping only the **10 most recent images**. Older untagged or superseded images are purged automatically to prevent storage cost creep.

### Strategy 4: CloudWatch Retention Policy
All application and cluster log groups enforce a **14-day retention period** (`retention_in_days = 14`), eliminating perpetual CloudWatch storage charges.

---

## 4. Teardown & Resource Cleanup Procedure

To terminate all cloud resources and avoid ongoing AWS charges when infrastructure is not in use:

```bash
cd terraform

# Destroy all provisioned infrastructure
terraform destroy -auto-approve
```

Verify deletion via AWS CLI:
```bash
aws eks list-clusters --region ap-south-1
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=project-management" --region ap-south-1
```
