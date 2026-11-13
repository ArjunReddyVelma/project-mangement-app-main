# DevOps Platform Architecture & System Design

## 1. Overview

The **Project Management DevOps Platform** is a production-grade, containerized Single Page Application (SPA) designed with defense-in-depth security, high availability, automated continuous integration & deployment (CI/CD), and end-to-end observability.

The architecture spans the entire software delivery lifecycle:
```
Developer Commit ──> GitHub Actions CI/CD ──> Security Gates ──> AWS ECR ──> Kubernetes (Kind / EKS) ──> Prometheus & Grafana
```

---

## 2. High-Level System Architecture

```mermaid
flowchart TD
    subgraph "External Clients & Ingress"
        Client["Browser User"]
        PromHost["Prometheus Scraper"]
    end

    subgraph "Kubernetes Namespace: project-dashboard"
        subgraph "Pod: project-dashboard"
            Nginx["Container: dashboard\n(Nginx 1.30.6-alpine3.24)\nNon-root UID 101\nRead-only Root FS"]
            Exporter["Container: nginx-exporter\n(v1.4.1)\nNon-root UID 1001\nRead-only Root FS"]
            TmpVol["emptyDir Volume (/tmp)"]
            
            Nginx --- TmpVol
            Exporter -->|"Local scrape\nhttp://127.0.0.1:8080/nginx_status"| Nginx
        end

        K8sSvc["Service: project-dashboard\nType: NodePort / ClusterIP\nPorts: 80 (App), 9113 (Metrics)"]
        HPA["HorizontalPodAutoscaler\nTarget: 70% CPU\nMin: 2, Max: 5"]
        
        K8sSvc -->|"Port 80 -> 8080"| Nginx
        K8sSvc -->|"Port 9113 -> 9113"| Exporter
        HPA -.->|"Scales"| Nginx
    end

    subgraph "Observability Stack"
        Prom["Prometheus v2.54.1"]
        AM["Alertmanager v0.27.0\n(Routing & Deduplication)"]
        Graf["Grafana v11.5.2"]
        Alerts["Alert Rules Engine\n(alert_rules.yml)"]
        
        Prom -->|"Scrapes :9113"| K8sSvc
        Prom --- Alerts
        Alerts -->|"Fires alerts"| AM
        Graf -->|"Queries :9090"| Prom
    end

    Client -->|"HTTP / (Port 80)"| K8sSvc
    PromHost -->|"Metrics (Port 9113)"| K8sSvc
```

---

## 3. End-to-End Delivery Pipeline (CI/CD)

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Engineer
    participant GH as GitHub Repository
    participant CI as GitHub Actions CI
    participant CD as GitHub Actions CD
    participant Trivy as Security Scanner
    participant ECR as AWS ECR
    participant EKS as Kubernetes (EKS / Kind)
    participant Obs as Prometheus / Grafana

    Dev->>GH: Push commit / Open PR
    GH->>CI: Trigger CI Workflow
    CI->>CI: Gitleaks Secret Detection (0 leaks)
    CI->>CI: npm ci && npm run lint && npm run build
    CI->>CI: Docker Build & Health Smoke Test
    CI->>Trivy: Trivy Filesystem, Config & Container Scan
    CI->>CI: Terraform fmt, init & validate
    CI-->>GH: Status: Success (All checks green)

    Dev->>GH: Merge to main branch / workflow_dispatch
    GH->>CD: Trigger CD Workflow
    CD->>CD: Pre-flight validation (AWS_ROLE_ARN check)
    CD->>CD: Build immutable Git commit image tag
    CD->>CD: Generate SPDX-JSON SBOM
    CD->>Trivy: Scan container image (CRITICAL,HIGH gate)
    CD->>ECR: OIDC Auth & Push immutable image
    ECR-->>CD: Return immutable imageDigest (@sha256:...)
    CD->>EKS: Rolling update deployment by imageDigest
    CD->>EKS: Verify rollout, readiness, and health endpoint
    alt Health Verification Fails
        CD->>EKS: Automated rollback (kubectl rollout undo)
    end
    EKS->>Obs: Exporter publishes metrics
    CD->>GH: Publish Deployment Summary
```

---

## 4. AWS Infrastructure Architecture (Terraform)

The infrastructure is provisioned through modular Terraform configurations adhering strictly to the principle of least privilege and CIS AWS Foundations benchmarks:

```mermaid
graph TD
    subgraph "AWS Cloud (ap-south-1)"
        subgraph "VPC: 10.0.0.0/16"
            subgraph "Public Subnets (AZ-a, AZ-b)"
                IGW["Internet Gateway"]
                NAT["NAT Gateway (Single EIP)"]
                PubSub["Public Subnets (map_public_ip: false)"]
            end
            
            subgraph "Private Subnets (AZ-a, AZ-b)"
                EKS_Control["EKS Cluster v1.31\n(Private API Endpoint: 443)\nAccess Config: API_AND_CONFIG_MAP"]
                EKS_Nodes["Managed Node Group\n(2x t3.medium instances)"]
            end
        end

        ECR["AWS ECR\n(Immutable, KMS Encrypted,\nLifecycle: 10 images)"]
        KMS["AWS KMS\n(Secrets Envelope Encryption)"]
        CW["CloudWatch Log Groups\n(/project-dashboard/dev\nRetention: 14 days)"]
        IAM["IAM Roles & Policies\n(EKS Cluster, Nodes, Scoped GitHub OIDC)"]
        AccessEntry["EKS Access Entry\n(AmazonEKSEditPolicy\nScope: namespace 'project-dashboard')"]
    end

    IGW --> NAT
    NAT --> EKS_Nodes
    EKS_Control --- KMS
    EKS_Nodes --- ECR
    EKS_Nodes --- CW
    IAM -.->|"Role Assumption"| EKS_Control
    IAM -.->|"Role Assumption"| EKS_Nodes
    IAM -.->|"OIDC Assume"| AccessEntry
    AccessEntry -.->|"Grants RBAC"| EKS_Control
```

---

## 5. Defense-in-Depth Security Design

| Layer | Implementation | Security Objective | Detailed Guide |
| :--- | :--- | :--- | :--- |
| **Source Code** | Gitleaks, Dependabot weekly updates, `npm audit` 0 vulnerabilities | Prevent secret leakage and unpatched dependencies. | [SECURITY.md](SECURITY.md) |
| **Base Image** | `nginx:1.30.6-alpine3.24` with `apk update && apk upgrade --no-cache` | Zero known High/Critical OS CVEs. | [SECURITY.md](SECURITY.md) |
| **Container Runtime** | Non-root execution (`USER nginx`, UID 101), `readOnlyRootFilesystem: true`, dropped capabilities (`ALL`), `allowPrivilegeEscalation: false` | Prevent container breakout and runtime modifications. | [SECURITY.md](SECURITY.md) |
| **Network Security** | Nginx status endpoint limited to `127.0.0.1`, `::1`, and private CIDRs; HTTP security headers (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`) | Prevent information disclosure and clickjacking. | [SECURITY.md](SECURITY.md) |
| **Private EKS Network** | Private EKS control plane API with Ephemeral Actions Runner Controller (ARC) architecture | Eliminate public internet exposure of Kubernetes control plane. | [DEPLOYMENT_NETWORK_ARCHITECTURE.md](DEPLOYMENT_NETWORK_ARCHITECTURE.md) |
| **IAM & EKS Access** | Scoped OIDC subject claims, `AmazonEKSEditPolicy` scoped to namespace `project-dashboard` | Enforce strict least-privilege deployment authorization. | [IAM_AND_EKS_ACCESS.md](IAM_AND_EKS_ACCESS.md) |
| **State Security** | S3 remote state architecture with SSE-KMS, versioning, TLS policy, and native lockfile support | Protect infrastructure state from corruption and data leakage. | [TERRAFORM_STATE_MANAGEMENT.md](TERRAFORM_STATE_MANAGEMENT.md) |
| **Infrastructure** | KMS envelope encryption for secrets, private node subnets, ECR KMS encryption, tag immutability | Secure cloud infrastructure posture. | [INFRASTRUCTURE_SECURITY_REVIEW.md](INFRASTRUCTURE_SECURITY_REVIEW.md) |
