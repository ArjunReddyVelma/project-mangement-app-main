# Security Architecture & Vulnerability Management Policy

## 1. Security Philosophy

This platform implements a **Shift-Left DevSecOps** model, enforcing continuous automated security validation at every phase of the development lifecycle:
- Code commits are scanned for secrets before entering the remote repository.
- Dependencies are audited and kept at 0 known vulnerabilities.
- Production container images run as unprivileged users with immutable, read-only filesystems.
- Deployment gates enforce zero Critical and High vulnerabilities with automated build failure.

---

## 2. Container Hardening Standard

### Multi-Stage Production Dockerfile
The production container enforces strict isolation controls:

1. **Non-Root Execution:**
   - Default user set to `USER nginx` (UID `101`, GID `101`).
   - Container cannot execute administrative commands or alter root system directories.
2. **Immutable Read-Only Filesystem:**
   - Root filesystem is mounted read-only (`readOnlyRootFilesystem: true`).
   - Writable directories are explicitly restricted to an ephemeral in-memory volume (`/tmp`) for PID and temporary buffers.
3. **Least Privilege Linux Capabilities:**
   - All default Linux capabilities dropped (`drop: ["ALL"]`).
   - Privilege escalation blocked (`allowPrivilegeEscalation: false`).
4. **Seccomp Profile:**
   - Enforces `RuntimeDefault` seccomp profile across all Kubernetes pods.
5. **Base Image Maintenance:**
   - Based on Alpine Linux (`nginx:1.30.6-alpine3.24`).
   - Production stage runs `apk update && apk upgrade --no-cache` to ensure newly published security patches are integrated immediately.

---

## 3. Vulnerability Scanning & Security Gates

### CI/CD Security Gates
The following security tools run automatically on every pull request and push to `main`:

| Scanner | Target | Configuration / Policy |
| :--- | :--- | :--- |
| **Gitleaks** | Repository Git History | Fails build if API keys, tokens, or private credentials are detected. |
| **Trivy Filesystem** | Source Code & Lockfiles | Scans npm dependencies and manifests for High & Critical CVEs. |
| **Trivy IaC / Config** | Dockerfile, K8s, Terraform | Validates cloud and container configurations against CIS benchmarks. |
| **Trivy Container** | Production Container Image | Strict threshold: `--severity CRITICAL,HIGH --exit-code 1 --ignore-unfixed true`. |
| **npm audit** | Node dependencies | Zero vulnerabilities permitted in production build dependencies. |

---

## 4. Software Supply Chain Security

### Software Bill of Materials (SBOM)
Every production build automatically generates a machine-readable Software Bill of Materials in standard SPDX-JSON format:
- Identifies all software packages, licenses, versions, and package hashes.
- Uploaded as an immutable build artifact to GitHub Actions for audit compliance.

### Image Provenance & Signing (Cosign)
In enterprise environments, container images are signed using Sigstore Cosign:
```bash
cosign sign --yes <account_id>.dkr.ecr.ap-south-1.amazonaws.com/project-management-dashboard:<sha>
```
Admission controllers (such as Kyverno or OPA Gatekeeper) verify cryptographic signatures before allowing image deployment into the cluster.

---

## 5. Cloud & Network Security

1. **Short-Lived GitHub OIDC Authentication (Strictly Scoped):**
   - Long-lived AWS access keys are strictly prohibited.
   - GitHub Actions authenticates directly to AWS STS using OpenID Connect (`token.actions.githubusercontent.com`).
   - Trust policy scopes role assumption strictly to verified branches and deployment environments: `repo:ArjunReddyVelma/project-mangement-app-main:ref:refs/heads/main`, `environment:staging`, and `environment:production`. Wildcard `*` matching is eliminated (see [IAM_AND_EKS_ACCESS.md](IAM_AND_EKS_ACCESS.md)).
2. **EKS Access Entries & Least-Privilege RBAC:**
   - EKS v1.31 native Access Entries manage cluster authentication (`API_AND_CONFIG_MAP` authentication mode).
   - The GitHub Actions deployment role is granted `AmazonEKSEditPolicy` scoped strictly to namespace `project-dashboard`, preventing unauthorized access to `kube-system` or cluster-scoped administration.
3. **Private EKS API Server & Runner Isolation:**
   - EKS API server endpoint public access is disabled (`endpoint_public_access = false`).
   - Workloads and CI/CD runners reside in private subnets with restricted egress filtered by VPC CIDR (see [DEPLOYMENT_NETWORK_ARCHITECTURE.md](DEPLOYMENT_NETWORK_ARCHITECTURE.md)).
4. **KMS Envelope Encryption:**
   - Kubernetes secrets stored in etcd are encrypted at rest using AWS KMS customer managed keys with annual key rotation enabled.
   - Amazon ECR container images and S3 Terraform state backends are encrypted using AWS KMS CMKs (see [TERRAFORM_STATE_MANAGEMENT.md](TERRAFORM_STATE_MANAGEMENT.md) and [INFRASTRUCTURE_SECURITY_REVIEW.md](INFRASTRUCTURE_SECURITY_REVIEW.md)).
5. **HTTP Security Headers:**
   - Nginx server configuration actively injects:
     - `X-Frame-Options: SAMEORIGIN`
     - `X-Content-Type-Options: nosniff`
     - `Referrer-Policy: strict-origin-when-cross-origin`
     - `server_tokens off;` (hiding Nginx version)

---

## 6. Software Supply Chain & Governance

Comprehensive supply chain security architecture, verification workflows, and policy enforcement specifications are documented in:
- **[SUPPLY_CHAIN_SECURITY.md](SUPPLY_CHAIN_SECURITY.md)**: Gitleaks automated scanning, SPDX SBOM generation, and Cosign keyless signing with Kyverno admission enforcement.
- **[TERRAFORM_STATE_MANAGEMENT.md](TERRAFORM_STATE_MANAGEMENT.md)**: S3 remote state isolation, TLS enforcement, SSE-KMS encryption, and native S3/DynamoDB state locking.
- **[INFRASTRUCTURE_SECURITY_REVIEW.md](INFRASTRUCTURE_SECURITY_REVIEW.md)**: Comprehensive CIS benchmark alignment, NAT Gateway availability vs cost trade-off, and IMDSv2 node hardening.

---

## 7. Vulnerability Disclosure & Exception Handling

If a third-party package reports a vulnerability with no available upstream fix (`unfixed`):
1. A security ticket must be filed documenting:
   - CVE identifier.
   - Exploitation probability in context of static React SPA runtime.
   - Proposed review date (not exceeding 30 days).
2. Broad suppression rules or disabling scanner exit codes are strictly forbidden.
