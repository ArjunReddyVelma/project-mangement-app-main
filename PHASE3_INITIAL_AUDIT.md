# Phase 3 Initial Architecture & Operational Audit

**Audit Date:** November 13, 2026  
**Auditor:** Senior DevOps & Cloud Infrastructure Engineer  
**Repository:** [ArjunReddyVelma/project-mangement-app-main](https://github.com/ArjunReddyVelma/project-mangement-app-main)  
**Branch:** `feature/devops-platform`  
**Latest Verified Commit:** `a60183573401307c4d51159863b9e10e083d007c`  
**Pull Request:** #5 (OPEN & UNMERGED)

---

## 1. Executive Summary

This initial audit evaluates the repository against production-readiness criteria across CI/CD, Kubernetes, AWS infrastructure (Terraform), DevSecOps, observability, and Site Reliability Engineering. While the Phase 2 baseline established a solid foundation (zero High/Critical Trivy vulnerabilities, hardened non-root container, functional Kind cluster, and initial Terraform modules), several critical blockers, security vulnerabilities, and operational gaps must be resolved before the platform can be deemed production-ready.

---

## 2. Existing Implementation & Confirmed Working Functionality

The following components were audited and verified as functioning correctly in the repository:

1. **React 19 + Vite 8 Frontend:**
   - Builds cleanly in 250ms with zero errors.
   - Linting with `oxlint` passes cleanly with zero errors.
   - `npm audit` reports 0 vulnerabilities.
2. **Container Runtime & Packaging:**
   - Multi-stage Docker build produces a lean `nginx:1.30.6-alpine3.24` image.
   - Runs as non-root `USER nginx` (UID 101).
   - Read-only root filesystem compatible (`readOnlyRootFilesystem: true`) using an ephemeral `/tmp` volume.
   - HTTP security headers (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`) and `server_tokens off;` enabled.
   - Trivy container scan reports **0 Critical, 0 High** vulnerabilities.
3. **Local Kubernetes Deployment (Kind):**
   - Verified 2-replica Deployment with startup, readiness, and liveness probes.
   - Sidecar `nginx-prometheus-exporter:1.4.1` scraping local `/nginx_status`.
   - NodePort and ClusterIP routing working with live CPU metrics via patched Metrics Server (`--kubelet-insecure-tls`).
   - Pod self-healing, rolling updates, and rollback verified locally.
4. **DevSecOps Scans in CI:**
   - Gitleaks secret scanner detected 0 leaks across 26 commits.
   - Trivy filesystem scan detected 0 CVEs in lockfiles.
   - Terraform formatting and validation pass cleanly.

---

## 3. Critical Security Weaknesses & Deployment Blockers

### A. CD Pipeline Correctness & False Positives (CRITICAL)
- **Problem:** In `.github/workflows/cd.yml`, the AWS OIDC authentication step uses `continue-on-error: true`. If AWS authentication fails (e.g., due to missing credentials, invalid role, or network error), the step is marked as failed, but all subsequent steps (`login-ecr`, `deploy`, `rollout`) are conditionally skipped via `if: steps.aws-auth.outcome == 'success'`. The workflow run finishes with an artificial **green "SUCCESS"** status despite zero deployment occurring!
- **Placeholder Account ID:** The fallback IAM role ARN uses a fake AWS account ID (`arn:aws:iam::123456789012:role/...`), which masks configuration errors.
- **Mutable Tagging:** CD deploys by updating the image tag to a short Git commit SHA (`${GITHUB_SHA::8}`) rather than deploying by immutable image digest (`@sha256:...`). If a tag is overwritten or points to another layer cache, non-deterministic deployments can occur.
- **Insufficient Health Gates:** Post-deployment verification merely runs `kubectl get pods,svc,hpa`, which will pass even if pods are in `CrashLoopBackOff` or endpoints are failing.

### B. Private EKS API Network Inaccessibility (CRITICAL)
- **Problem:** The Terraform EKS module sets `endpoint_public_access = false` and `endpoint_private_access = true`. While this adheres to CIS hardening recommendations by shielding the control plane from the public internet, GitHub-hosted runners (`ubuntu-24.04`) reside in GitHub's public cloud network. A hosted runner has no network route into the AWS VPC private subnets, causing `aws eks update-kubeconfig` and subsequent `kubectl` commands to hang or time out.
- **Remediation Required:** Architectural analysis and implementation of an ephemeral or self-hosted VPC runner architecture, or private endpoint proxy strategy without weakening the cluster's public attack surface.

### C. Overly Permissive IAM OIDC Trust Policy & Missing EKS RBAC (HIGH)
- **Overly Broad Subject Claim:** In `terraform/modules/iam/main.tf`, the GitHub OIDC assume role policy uses `repo:ArjunReddyVelma/project-mangement-app-main:*`. This permits any commit, branch, or untrusted pull request to assume the AWS deployment role. It must be restricted strictly to authorized environments (`environment:production`, `environment:staging`) and protected branches (`ref:refs/heads/main`).
- **Missing EKS Access Entries:** IAM authentication gives an IAM role ARN upon STS assumption, but modern EKS (v1.31) requires explicit cluster access entries (`aws_eks_access_entry` and `aws_eks_access_policy_association`). Without these, the deployment role will receive `401 Unauthorized` or `403 Forbidden` from the Kubernetes API server.
- **Least-Privilege Scoping:** The role must be granted `AmazonEKSEditPolicy` scoped strictly to namespace `project-dashboard`, rather than broad `cluster-admin`.

### D. Terraform Remote State Security & Bootstrap (MEDIUM)
- **Unmanaged State:** `terraform/backend.tf` is currently commented out, leaving the platform reliant on local ephemeral state. A production deployment requires an S3 remote backend with AES256/KMS encryption, versioning, public access blocking, TLS enforcement, and state locking.
- **Locking Architecture:** OpenTofu 1.6+ and Terraform 1.10+ introduce native S3 locking via S3 conditional writes, alongside legacy DynamoDB table locking.

### E. Single NAT Gateway Availability vs Cost Trade-off (MEDIUM)
- **Single Point of Failure:** `modules/vpc` deploys a single NAT Gateway in public subnet `AZ-a`. If `AZ-a` experiences an AWS facility outage, private subnets in `AZ-b` lose internet egress. However, provisioning multi-AZ NAT Gateways triples monthly NAT costs (~$100/mo vs $32.85/mo). This trade-off must be formalized with dual architectures (dev vs prod).

### F. Observability Maturity & Alert Routing (MEDIUM)
- **Missing Alertmanager:** Prometheus alert rules are defined, but no Alertmanager service exists in Docker Compose to deduplicate, group, and route notifications.
- **Phantom Metrics in Compose:** Rules in `alert_rules.yml` reference cAdvisor and kube-state-metrics counters (`container_cpu_usage_seconds_total`, `kube_pod_container_status_restarts_total`) which do not exist in standard Docker Compose scraping, creating silent rule evaluation gaps.

---

## 4. Technical Debt Inventory

| ID | Component | Description | Severity | Remediation Phase |
| :--- | :--- | :--- | :--- | :--- |
| **TD-01** | CI/CD | `cd.yml` masks AWS auth failure via `continue-on-error: true` | **CRITICAL** | Phase 1 |
| **TD-02** | Network | Private EKS API unreachable from GitHub-hosted runners | **CRITICAL** | Phase 2 |
| **TD-03** | IAM | GitHub OIDC trust policy wildcard `*` allows unauthorized branches | **HIGH** | Phase 3 |
| **TD-04** | EKS | Missing `aws_eks_access_entry` mapping IAM role to K8s RBAC | **HIGH** | Phase 3 |
| **TD-05** | CD Artifacts | Deploys using mutable tag instead of immutable sha256 digest | **HIGH** | Phase 1 |
| **TD-06** | CD Rollback | Rollback step does not verify restored application health | **HIGH** | Phase 1 |
| **TD-07** | Terraform | No active S3 remote state architecture with distributed locking | **MEDIUM** | Phase 4 |
| **TD-08** | Monitoring | Missing Alertmanager container and notification routing in Compose | **MEDIUM** | Phase 6 |
| **TD-09** | VPC | Undocumented single NAT Gateway availability trade-off | **MEDIUM** | Phase 5 |
| **TD-10** | DevSecOps | Missing Cosign container image signing verification | **LOW** | Phase 8 |

---

## 5. Recommended Remediation Order

1. **Remediation Step 1 (Phase 1): CD Pipeline Correctness:**
   - Remove `continue-on-error: true` on AWS OIDC authentication.
   - Enforce deployment gates: fail immediately if credentials or configuration are missing.
   - Capture registry image digest (`@sha256:...`) and deploy via immutable digest.
   - Enhance deployment health verification (readiness probe, replica counts, active endpoint curl).
   - Implement robust rollback with post-rollback verification and failure preservation.
2. **Remediation Step 2 (Phase 2): Private EKS Network Architecture:**
   - Formulate and document the network architecture for private EKS deployment via self-hosted ephemeral VPC runner.
   - Author `DEPLOYMENT_NETWORK_ARCHITECTURE.md`.
3. **Remediation Step 3 (Phase 3): IAM Least-Privilege & EKS Access Entries:**
   - Restrict GitHub OIDC trust policy to specific environment and branch contexts.
   - Implement `aws_eks_access_entry` and `aws_eks_access_policy_association` in `modules/eks/` scoped to `project-dashboard`.
   - Author `IAM_AND_EKS_ACCESS.md`.
4. **Remediation Step 4 (Phase 4): Terraform State Security:**
   - Create `terraform/backend.tf.example` and `TERRAFORM_STATE_MANAGEMENT.md` with S3 versioning, encryption, and locking.
5. **Remediation Step 5 (Phase 5): Network & Infrastructure Hardening:**
   - Document single vs multi-AZ NAT Gateway architectures and author `INFRASTRUCTURE_SECURITY_REVIEW.md`.
6. **Remediation Step 6 (Phase 6): Observability & Alertmanager Maturity:**
   - Add Alertmanager to Docker Compose, route alerts by severity, and update `MONITORING.md`.
7. **Remediation Step 7 (Phases 7 & 8): SRE & Supply Chain Security:**
   - Author `SRE_VALIDATION_REPORT.md` and `SUPPLY_CHAIN_SECURITY.md` with Cosign analysis.
8. **Remediation Step 8 (Phases 9-12): Documentation, Full Verification & Final Report:**
   - Update all documentation files and generate `PHASE3_IMPLEMENTATION_REPORT.md`.
