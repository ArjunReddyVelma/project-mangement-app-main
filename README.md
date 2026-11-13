# Project Management Dashboard — Enterprise DevOps Platform

[![CI Pipeline](https://github.com/ArjunReddyVelma/project-mangement-app-main/actions/workflows/ci.yml/badge.svg)](https://github.com/ArjunReddyVelma/project-mangement-app-main/actions/workflows/ci.yml)
[![Security Scan](https://img.shields.io/badge/Trivy-0%20High%2F0%20Critical-brightgreen)](SECURITY.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-blue.svg)](k8s/)
[![Terraform](https://img.shields.io/badge/Terraform-AWS%20Modular-purple.svg)](terraform/)

An end-to-end, enterprise-grade DevOps platform built around a React + Vite project management dashboard. The architecture implements the complete operational lifecycle:
```
Developer ──> GitHub ──> CI (Lint/Build/Security) ──> CD (OIDC/ECR) ──> Kubernetes (Kind/EKS) ──> Observability (Prometheus/Grafana) ──> SRE Runbooks
```

---

## 📑 Platform Documentation Index

### Core Architecture & Operations
| Document | Purpose |
| :--- | :--- |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | End-to-end system architecture, Mermaid sequence and topology diagrams, defense-in-depth security model. |
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Complete step-by-step guides for local Kind Kubernetes deployment, rolling updates, rollbacks, and AWS EKS. |
| **[SECURITY.md](SECURITY.md)** | DevSecOps policy, non-root container standards, zero-tolerance vulnerability gates, SPDX SBOM, and OIDC IAM. |
| **[MONITORING.md](MONITORING.md)** | Observability architecture, Alertmanager routing, Prometheus metrics, and Grafana dashboard definitions. |
| **[RUNBOOK.md](RUNBOOK.md)** | Incident response playbooks covering simulated failure scenarios, SLOs/SLIs, and MTTD/MTTR targets. |
| **[DISASTER_RECOVERY.md](DISASTER_RECOVERY.md)** | Business continuity plan, RTO/RPO objectives, cluster re-creation, and regional failover strategies. |
| **[COST_ESTIMATION.md](COST_ESTIMATION.md)** | Line-item AWS cost analysis ($178.34/mo baseline, $135.80/mo spot-optimized), and teardown procedures. |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common operational issues, root cause diagnostics, and verified remediation commands. |

### Phase 3 Production Readiness & Governance
| Document | Purpose |
| :--- | :--- |
| **[PHASE3_INITIAL_AUDIT.md](PHASE3_INITIAL_AUDIT.md)** | Baseline audit of Phase 2 architecture, identifying CD false-positives, private EKS routing, and state risks. |
| **[DEPLOYMENT_NETWORK_ARCHITECTURE.md](DEPLOYMENT_NETWORK_ARCHITECTURE.md)** | Comparative evaluation of private EKS CI/CD runner architectures; selects and specs ephemeral ARC. |
| **[IAM_AND_EKS_ACCESS.md](IAM_AND_EKS_ACCESS.md)** | Scoped OIDC subject claims and modern AWS EKS v1.31 Access Entry RBAC policy configuration. |
| **[TERRAFORM_STATE_MANAGEMENT.md](TERRAFORM_STATE_MANAGEMENT.md)** | S3 remote state architecture, SSE-KMS encryption, bucket policies, and OpenTofu/Terraform lockfiles. |
| **[INFRASTRUCTURE_SECURITY_REVIEW.md](INFRASTRUCTURE_SECURITY_REVIEW.md)** | CIS AWS Foundations compliance review, NAT Gateway availability vs cost trade-off analysis. |
| **[SRE_VALIDATION_REPORT.md](SRE_VALIDATION_REPORT.md)** | Empirical validation of 8 failure scenarios in Kind, zero-downtime rollouts, and SLO vs SLA definitions. |
| **[SUPPLY_CHAIN_SECURITY.md](SUPPLY_CHAIN_SECURITY.md)** | Gitleaks secrets scanning, Trivy image vetting, SPDX SBOM generation, and Cosign/Kyverno admission. |
| **[PHASE3_IMPLEMENTATION_REPORT.md](PHASE3_IMPLEMENTATION_REPORT.md)** | Comprehensive Phase 3 executive report, verification matrix, remaining risks, and readiness assessment. |

### Phase 4 Production Deployment, GitOps & Release Engineering
| Document | Purpose |
| :--- | :--- |
| **[PHASE4_INITIAL_AUDIT.md](PHASE4_INITIAL_AUDIT.md)** | Comprehensive audit of local/CI capabilities vs. live AWS deployment requirements and financial gates. |
| **[AWS_DEPLOYMENT_PREREQUISITES.md](AWS_DEPLOYMENT_PREREQUISITES.md)** | Complete AWS account configuration, IAM permissions, GitHub secrets, and $176.94/mo cost gate. |
| **[ARC_DEPLOYMENT_REPORT.md](ARC_DEPLOYMENT_REPORT.md)** | Ephemeral Actions Runner Controller (ARC) Helm deployment and private EKS API connectivity. |
| **[ECR_RELEASE_VERIFICATION.md](ECR_RELEASE_VERIFICATION.md)** | Short-lived OIDC STS authentication, immutable ECR digest promotion, and SPDX SBOM provenance. |
| **[EKS_PRODUCTION_DEPLOYMENT_REPORT.md](EKS_PRODUCTION_DEPLOYMENT_REPORT.md)** | Workload manifests, AWS ALB Ingress Controller, TLS redirection, and HPA autoscaling. |
| **[PRODUCTION_OBSERVABILITY_REPORT.md](PRODUCTION_OBSERVABILITY_REPORT.md)** | 10 core telemetry signals, Alertmanager routing, inhibition rules, and Grafana PromQL reference. |
| **[PRODUCTION_FAILURE_TEST_REPORT.md](PRODUCTION_FAILURE_TEST_REPORT.md)** | 10 empirical failure simulation walkthroughs with real recovery and automated rollback timings. |
| **[GITOPS_RELEASE_STRATEGY.md](GITOPS_RELEASE_STRATEGY.md)** | Evaluation of push vs. pull CD, single deployment authority, and declarative Kustomize overlays. |
| **[AWS_OPERATIONS_AND_COST_CONTROL.md](AWS_OPERATIONS_AND_COST_CONTROL.md)** | AWS budget alerts, cost allocation tags, 14-day retention, 10-image ECR lifecycle, and teardown script. |
| **[PHASE4_FINAL_IMPLEMENTATION_REPORT.md](PHASE4_FINAL_IMPLEMENTATION_REPORT.md)** | Final Phase 4 engineering report, status classification matrix, and cloud authorization gate. |

---

## 🚀 Key DevOps Capabilities Demonstrated

1. **Production-Hardened Containerization:**
   - Multi-stage Docker build producing a minimal Alpine Nginx runtime.
   - Non-root user execution (`USER nginx`, UID 101).
   - Immutable read-only root filesystem (`readOnlyRootFilesystem: true`) with `/tmp` emptyDir scratch volume.
   - Dropped Linux capabilities (`drop: ["ALL"]`) and `allowPrivilegeEscalation: false`.
   - Patched Alpine OS libraries resulting in **0 High and 0 Critical CVEs**.
2. **Local & Cloud Kubernetes (Kind & AWS EKS):**
   - High availability with 2 replicas across multi-AZ node groups.
   - Startup, readiness, and liveness HTTP probes.
   - CPU-based Horizontal Pod Autoscaling (70% target, 2 to 5 replicas).
   - Metrics Server integration and sidecar metric collection (`nginx-prometheus-exporter`).
   - Verified rolling update zero-downtime rollouts and automated rollbacks on failure.
   - Scoped AWS EKS v1.31 Access Entries mapped strictly to namespace `project-dashboard`.
3. **Full Observability & Alerting Stack:**
   - Pre-provisioned **Grafana 11.5.2** dashboard (**DevOps Platform Overview**).
   - **Prometheus 2.54.1** metrics engine with 6 automated alert rules across infrastructure and application tiers.
   - **Alertmanager 0.27.0** routing engine with severity grouping (critical vs warning), deduplication, and inhibition.
   - Sidecar architecture exporting connection states and request counters.
   - Local Docker Compose stack strictly bound to loopback `127.0.0.1` for host protection.
4. **Shift-Left DevSecOps Pipeline:**
   - **Gitleaks** automated secret scanning on all commits.
   - **Trivy** scanning across filesystem, container images, Kubernetes manifests, and Terraform IaC.
   - Pinned GitHub Actions commit SHAs for supply chain integrity.
   - Automated SPDX-JSON Software Bill of Materials (SBOM) generation.
   - Dependabot weekly updates across npm, Docker, GitHub Actions, and Terraform.
5. **Modular Infrastructure as Code (Terraform):**
   - Clean reusable modules for `vpc`, `iam`, `ecr`, `eks`, and `cloudwatch`.
   - Short-lived GitHub Actions OIDC federation with strictly scoped branch/environment subject claims.
   - KMS customer-managed key encryption for Kubernetes secrets and ECR container repositories.
   - Remote state configuration blueprint with S3 versioning, TLS enforcement, and lockfiles.

---

## ⚡ Quick Start

### 1. Run Local Observability Stack (Docker Compose)

```bash
docker compose up -d --build
```

Access services locally:
- **Dashboard:** http://localhost:8080
- **Health Check:** http://localhost:8080/health
- **Nginx Exporter Metrics:** http://localhost:9113/metrics
- **Prometheus UI:** http://localhost:9090
- **Alertmanager UI:** http://localhost:9093
- **Grafana Dashboard:** http://localhost:3000 (User: `admin`, Pass: `admin`)

Stop stack:
```bash
docker compose down
```

---

### 2. Run in Local Kubernetes Cluster (Kind)

```bash
# 1. Create Kind cluster with port mapping
kind create cluster --name devops-platform --config k8s/kind-config.yaml

# 2. Build and load production image
docker build -t project-dashboard:local .
kind load docker-image project-dashboard:local --name devops-platform
docker exec devops-platform-control-plane crictl pull nginx/nginx-prometheus-exporter:1.4.1

# 3. Deploy Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 4. Deploy Application Manifests
kubectl apply -f k8s/project-dashboard.yaml

# 5. Verify Rollout & Health
kubectl rollout status deployment/project-dashboard -n project-dashboard
curl -i http://localhost:8080/health
```

---

## 🔒 Security & Verification Matrix

| Gate / Check | Tool / Standard | Result | Status |
| :--- | :--- | :--- | :--- |
| **npm Dependencies** | `npm audit` / `npm ci` | 0 Vulnerabilities | ✅ PASS |
| **Code Linting** | `oxlint` | 0 Errors | ✅ PASS |
| **Secret Scanning** | Gitleaks v8 | 0 Leaks Found across 32 commits | ✅ PASS |
| **Filesystem CVEs** | Trivy FS | 0 High / 0 Critical | ✅ PASS |
| **Container CVEs** | Trivy Container (Alpine 3.24) | 0 High / 0 Critical | ✅ PASS |
| **IaC Misconfiguration** | Trivy Config (K8s & Terraform) | 0 Misconfigurations | ✅ PASS |
| **Container Security Context** | Non-root (UID 101), ReadOnly Root FS | Enforced | ✅ PASS |
| **Terraform IaC Validation** | `terraform validate` & `fmt` | Valid & Formatted | ✅ PASS |
| **Local K8s Rollout & Undo** | Kubernetes Deployment & HPA | Verified (2/2 Ready, Rollback tested) | ✅ PASS |

---

## 🛠️ Technology Stack

- **Frontend:** React 19, Vite 8, Lucide React, JavaScript (ESM)
- **Web Server:** Nginx 1.30.6 (Alpine 3.24 hardened runtime)
- **Orchestration:** Kubernetes 1.31, Kind (Local), AWS EKS (Cloud)
- **Infrastructure as Code:** Terraform >= 1.6 / OpenTofu (AWS Provider ~> 5.0)
- **Monitoring & SRE:** Prometheus v2.54.1, Grafana 11.5.2, Nginx Prometheus Exporter 1.4.1
- **Security & DevSecOps:** Trivy 0.60.0, Gitleaks, GitHub OIDC, Dependabot, SPDX SBOM
- **CI/CD:** GitHub Actions (SHA-pinned workflows)
