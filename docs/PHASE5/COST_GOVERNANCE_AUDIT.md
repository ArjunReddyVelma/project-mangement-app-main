# Cost & Operational Governance Audit Report

## 1. Executive Summary

This audit evaluates the financial estimates, cloud spending assumptions, and operational governance policies of the **Project Management Dashboard DevOps Platform**.

### Key Audit Finding
The Phase 4 baseline cost estimate of **$176.94/month** (and Spot estimate of **$134.45/month**) omitted essential infrastructure components required for an external-facing production deployment, notably the **AWS Application Load Balancer (ALB)** and **NAT Gateway data processing charges**.

Accounting for these omitted production elements elevates the realistic baseline monthly run rate to **~$199.84 / month** (or **~$157.35 / month** when spot-optimized).

---

## 2. Reconciled Production Cost Breakdown (ap-south-1)

| Cost Category | Phase 4 Reported | Audited Reality | Variance | Omission / Audit Finding |
| :--- | :---: | :---: | :---: | :--- |
| **EKS Control Plane** | $73.00 | $73.00 | $0.00 | $0.10/hour fixed control plane charge. Unavoidable. |
| **EC2 Worker Nodes (2 × t3.medium)** | $60.74 | $60.74 | $0.00 | 2 × $0.0416/hr On-Demand. Can be reduced to $18.25 with Spot. |
| **AWS NAT Gateway (Runtime)** | $32.85 | $32.85 | $0.00 | $0.045/hour base charge for 1 Gateway. |
| **NAT Data Processing** | Omitted | $2.25 | **+$2.25** | $0.045/GB processed. Container image pulls and updates. |
| **AWS Application Load Balancer** | Omitted | $18.20 | **+$18.20** | $0.0225/hr ($16.20) + minimum 1 LCU ($2.00) required for ALB Ingress. |
| **EBS gp3 Storage (2 × 20GB)** | $3.20 | $3.20 | $0.00 | $0.08/GB-month for 40GB total. |
| **AWS KMS Customer Managed Keys** | $2.00 | $2.00 | $0.00 | 2 CMKs (EKS etcd + ECR) @ $1.00/key/month. |
| **Amazon CloudWatch Logs** | $2.85 | $2.85 | $0.00 | Ingestion of ~5GB audit and container logs @ $0.57/GB. |
| **Amazon ECR Storage & Transfer** | $2.30 | $2.30 | $0.00 | 10 images (~500MB) + cross-AZ transfer. |
| **Amazon Route 53 (DNS)** | Omitted | $0.50 | **+$0.50** | 1 Hosted Zone for custom domain routing. |
| **AWS Certificate Manager (ACM)** | $0.00 | $0.00 | $0.00 | Free public SSL/TLS certificates for ALB. |
| **ARC Ephemeral Runners** | $0.00 | $0.00 | $0.00 | Runs inside existing EC2 node capacity (shared CPU). |
| **RECONCILED BASELINE TOTAL:** | **$176.94** | **$199.84 / mo** | **+$22.90** | **Comprehensive Production Baseline** |
| **SPOT-OPTIMIZED TOTAL:** | **$134.45** | **$157.35 / mo** | **+$22.90** | **With Spot EC2 Compute ($18.25/mo)** |

---

## 3. Financial Controls & Cost Containment Safeguards

### 1. Mandatory AWS Budget Alerting
Configured in `terraform/budget.tf` to monitor the $200.00 monthly threshold:
- **80% Actual Spend ($160.00):** Sends early warning alert to `devops-alerts@example.com`.
- **100% Forecasted Spend ($200.00):** Sends high-priority escalation to `devops-lead@example.com` before billing overrun occurs.

### 2. Mandatory Cost Allocation Tagging
The AWS provider enforces global default tags across all billable resources:
- `Project`: `project-management`
- `Environment`: `dev` / `staging` / `prod`
- `ManagedBy`: `Terraform`
- `Owner`: `DevOps-Platform-Team`
- `CostCenter`: `Engineering-Core-104`

### 3. Automated Storage & Telemetry Purging
- **Amazon ECR:** Lifecycle policy keeps only the **10 most recent container images**, expiring stale images automatically to cap registry storage under 500MB (< $0.05/mo).
- **CloudWatch Logs:** Explicit **14-day retention window** enforced across `/project-dashboard/*` and `/aws/eks/*/cluster` log groups.

---

## 4. Teardown Safety & State Preservation Audit

### Critical Finding: State Deletion Risk in Previous Documentation
In Phase 4, the teardown script in `AWS_OPERATIONS_AND_COST_CONTROL.md` executed:
```bash
aws s3 rb "s3://${BUCKET_NAME}" --force
```
This action permanently deleted the remote Terraform state bucket. 

### Hardened Teardown Architecture (`scripts/teardown.sh`):
1. **Interactive Account ID & Environment Check:** Prompts the user to confirm the exact AWS Account ID and environment name (`dev` / `prod`) before any destruction begins.
2. **State Backup Export:** Pulls the remote state file (`terraform.tfstate`) and saves an encrypted local backup before calling `terraform destroy`.
3. **Preserves State Storage by Default:** Destroys all billable compute, networking, and cluster infrastructure, but **preserves the S3 state bucket and DynamoDB table** by default to maintain the audit trail and state history.

---

## 5. Audit Conclusion

The audited production monthly run rate is **$199.84 / month** (or **$157.35 / month** with Spot instances). All cost control policies (ECR 10-image lifecycle, 14-day log retention, AWS budgets) are structurally sound. Implementing the hardened `scripts/teardown.sh` script resolves the high-severity state destruction risk.