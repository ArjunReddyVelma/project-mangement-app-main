# AWS Deployment Prerequisites & Cost Gate Analysis

## 1. Overview

This document specifies the complete pre-flight requirements, identity federation setup, permission boundaries, and line-item financial cost analysis required to execute a secure deployment of the **Project Management Dashboard DevOps Platform** to Amazon Web Services (**AWS**).

Target Deployment Region: **`ap-south-1` (Asia Pacific - Mumbai)**

> [!IMPORTANT]
> In accordance with strict engineering safety constraints, **no paid AWS resources will be provisioned without explicit stakeholder approval**. This document serves as the authorization gate before any Terraform apply or state bootstrap execution.

---

## 2. Required AWS Account Configuration

1. **Active AWS Account & Region Availability:**
   - Account in good standing with billing enabled in `ap-south-1`.
   - Default VPC retained or dedicated CIDR space planned (`10.0.0.0/16`).
2. **EC2 Service Quotas:**
   - Standard (A, C, D, H, I, M, R, T, Z) On-Demand instance vCPU quota: Minimum 8 vCPUs (2 × `t3.medium` nodes = 4 vCPUs; burst headroom for node upgrades and HPA scale-up).
3. **AWS STS Endpoint:**
   - Global STS endpoint activated and configured to issue regional tokens (`ap-south-1`).

---

## 3. Required IAM Provisioning Permissions

The engineer or CI/CD bootstrap identity running `terraform apply` requires the following policy actions (or `AdministratorAccess` / `PowerUserAccess` scoped to project prefix `project-management-*`):

| AWS Service | Required IAM Actions |
| :--- | :--- |
| **VPC / EC2 Networking** | `ec2:CreateVpc`, `ec2:DeleteVpc`, `ec2:CreateSubnet`, `ec2:CreateNatGateway`, `ec2:AllocateAddress`, `ec2:CreateRouteTable`, `ec2:CreateInternetGateway`, `ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:AuthorizeSecurityGroupEgress`, `ec2:CreateTags` |
| **IAM & OIDC** | `iam:CreateRole`, `iam:DeleteRole`, `iam:AttachRolePolicy`, `iam:CreatePolicy`, `iam:PutRolePolicy`, `iam:CreateOpenIDConnectProvider`, `iam:TagRole` |
| **Amazon ECR** | `ecr:CreateRepository`, `ecr:DeleteRepository`, `ecr:PutLifecyclePolicy`, `ecr:PutImageScanningConfiguration`, `ecr:PutEncryptionConfiguration`, `ecr:SetRepositoryPolicy` |
| **AWS KMS** | `kms:CreateKey`, `kms:EnableKeyRotation`, `kms:CreateAlias`, `kms:TagResource`, `kms:ScheduleKeyDeletion` |
| **Amazon EKS** | `eks:CreateCluster`, `eks:DeleteCluster`, `eks:DescribeCluster`, `eks:CreateNodegroup`, `eks:DeleteNodegroup`, `eks:CreateAccessEntry`, `eks:DeleteAccessEntry`, `eks:AssociateAccessPolicy`, `eks:DisassociateAccessPolicy` |
| **Amazon CloudWatch** | `logs:CreateLogGroup`, `logs:DeleteLogGroup`, `logs:PutRetentionPolicy`, `logs:TagResource` |
| **Amazon S3 & DynamoDB** (State) | `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutBucketEncryption`, `s3:PutBucketPolicy`, `dynamodb:CreateTable` |

---

## 4. Required GitHub Secrets, Variables & Environment Protection

### Repository Secrets
Configured in GitHub Repository Settings → Secrets and variables → Actions:

| Secret Name | Value Description | Example / Format |
| :--- | :--- | :--- |
| `AWS_ROLE_ARN` | IAM Role ARN assumed via GitHub Actions OIDC federation | `arn:aws:iam::123456789012:role/project-management-dev-github-cd-role` |

### Repository Variables
| Variable Name | Value Description | Value |
| :--- | :--- | :--- |
| `AWS_REGION` | AWS target deployment region | `ap-south-1` |
| `ECR_REPOSITORY` | Container image repository name | `project-management-dashboard` |
| `EKS_CLUSTER_NAME` | Target Amazon EKS cluster name | `project-management-dev-eks` |

### GitHub Environment Protection Rules
For enterprise continuous deployment, the following environments should be configured with required reviewers:
1. `staging`: Automatic deployment on merge to `main`.
2. `production`: Mandatory manual approval gate with required team reviewers before executing CD deployment steps.

---

## 5. Comprehensive Infrastructure Cost Gate (ap-south-1)

### Line-Item Cost Breakdown

```
+---------------------------------------------------------------------------------+
| AWS Infrastructure Line-Item Cost Estimate (ap-south-1 - Mumbai)                |
+---------------------------------+---------------------+-------------------------+
| Service Component               | Specification       | Monthly Cost (USD)      |
+---------------------------------+---------------------+-------------------------+
| 1. Amazon EKS Control Plane     | 1 Managed Cluster   | $73.00                  |
| 2. EC2 Worker Nodes             | 2 x t3.medium       | $60.74                  |
| 3. AWS Managed NAT Gateway      | 1 Single-AZ Gateway | $32.85                  |
| 4. Elastic IP (NAT attached)    | 1 IPv4 Address      | $0.00 (No idle charge)  |
| 5. EBS gp3 Root Storage         | 2 x 20GB gp3 Volumes| $3.20                   |
| 6. AWS KMS Customer Managed Keys| 2 CMKs (EKS + ECR)  | $2.00                   |
| 7. Amazon CloudWatch Logs       | ~5GB Log Ingestion  | $2.85                   |
| 8. Amazon ECR Storage & Egress  | 10 Retained Images  | $0.50                   |
| 9. Inter-AZ / Outbound Data     | ~20GB Data Transfer | $1.80                   |
| 10. ARC Runner Overhead         | Ephemeral Pods (K8s)| $0.00 (Shared nodes)    |
+---------------------------------+---------------------+-------------------------+
| TOTAL ESTIMATED BASELINE RECURRING MONTHLY COST:      | $176.94 / month         |
+-------------------------------------------------------+-------------------------+
```

### One-Time Costs
- **Infrastructure Creation:** $0.00 (AWS API calls for resource provisioning are non-billable).
- **Initial Container Base Layers:** < $0.05 (One-time network ingress/data transfer).

### Cost Optimization & Cheaper Development Alternatives
For development, staging, or academic evaluation, multiple strategies can drastically lower cloud expenses:

1. **Spot Instance Worker Nodes:**
   - Configure `capacity_type = "SPOT"` on the EKS node group.
   - Spot price for `t3.medium` in `ap-south-1` averages **$0.0125/hr** (70% discount vs $0.0416/hr).
   - Reduces monthly node cost from $60.74 to **$18.25**, saving **$42.49/month**.
2. **Scheduled Working Hours Automation:**
   - Utilizing an AWS Instance Scheduler or Lambda to scale node group to 0 replicas outside business hours (e.g., 8 hours/day, 5 days/week = 160 hours/month).
   - Reduces node compute costs to **$6.65/month** and NAT gateway runtime to **$7.20/month**.
3. **Single NAT Gateway (Already Adopted):**
   - The infrastructure configures 1 shared NAT Gateway rather than multi-AZ NAT Gateways, immediately saving **$32.85/month**.

---

## 6. Teardown Requirements & Clean Removal Sequence

To ensure zero lingering costs when testing or operational cycles conclude, execute the reverse dependency teardown:

```bash
# 1. Delete Kubernetes workloads to unbind dynamic AWS resources (e.g., Load Balancers, PVs)
kubectl delete -f k8s/project-dashboard.yaml --ignore-not-found=true

# 2. Authenticate to Terraform directory
cd terraform

# 3. Destroy managed cloud infrastructure
terraform destroy -auto-approve

# 4. Remove remote state S3 bucket and DynamoDB lock table (if decommissioning project)
aws s3 rb s3://project-management-terraform-state-<account_id>-ap-south-1 --force
aws dynamodb delete-table --table-name project-management-terraform-locks --region ap-south-1
```

---

## 7. Cloud Authorization Checkpoint

```
[ STOP: CLOUD PROVISIONING GATE ]
- Pre-flight prerequisites: DOCUMENTED
- IAM permission boundaries: SPECIFIED
- Cost analysis: $176.94/mo baseline ($73 EKS + $60.74 EC2 + $32.85 NAT + $10.35 storage/logs/keys)
- Workstation AWS CLI / credentials: NOT CONFIGURED ON HOST
- User approval for paid provisioning: PENDING EXPLICIT AUTHORIZATION
- Status: READY FOR PROVISIONING UPON CREDENTIAL CONFIGURATION & USER APPROVAL
```