# Deployment Guide: Local Kind & AWS Production

## 1. Prerequisites

Ensure the following tools are installed on your workstation:
- **Docker Engine / Desktop** (v24.0+)
- **Kind** (Kubernetes in Docker, v0.30+)
- **Kubectl** (v1.28+)
- **Terraform / OpenTofu** (v1.6+)
- **AWS CLI** (v2.15+)

---

## 2. Local Kubernetes Environment (Kind)

### Step 1: Create Kind Cluster with Port Mapping
The repository provides `k8s/kind-config.yaml` with host port mappings (`8080` for web traffic, `9113` for metrics):

```bash
kind create cluster --name devops-platform --config k8s/kind-config.yaml
```

### Step 2: Build & Load Production Images
Build the production-hardened multi-stage Docker image and load it directly into the Kind cluster:

```bash
# Build application image
docker build -t project-dashboard:local .

# Load into Kind node
kind load docker-image project-dashboard:local --name devops-platform

# Load or pull exporter sidecar inside Kind
docker exec devops-platform-control-plane crictl pull nginx/nginx-prometheus-exporter:1.4.1
```

### Step 3: Deploy Metrics Server
Kind clusters require Metrics Server with insecure kubelet TLS communication:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl rollout status -n kube-system deployment metrics-server --timeout=60s
```

### Step 4: Deploy Dashboard Workloads
Apply the Kubernetes namespace, deployment, service, and HPA:

```bash
kubectl apply -f k8s/project-dashboard.yaml
kubectl rollout status deployment/project-dashboard -n project-dashboard --timeout=60s
```

### Step 5: Verify Deployment Health
```bash
# Verify pods and service
kubectl get pods,svc,hpa -n project-dashboard

# Test application endpoint
curl -i http://localhost:8080/health

# Test metrics endpoint
curl -s http://localhost:9113/metrics | grep nginx_up
```

---

## 3. Deployment Updates & Rolling Rollout

To perform a zero-downtime rolling update:

```bash
# Build and tag new version
docker build -t project-dashboard:v2 .
kind load docker-image project-dashboard:v2 --name devops-platform

# Update deployment image
kubectl set image deployment/project-dashboard dashboard=project-dashboard:v2 -n project-dashboard

# Monitor rollout progression
kubectl rollout status deployment/project-dashboard -n project-dashboard --timeout=60s
```

### Rollback Procedure
If an issue occurs during or after rollout:

```bash
# Undo rollout to restore previous revision
kubectl rollout undo deployment/project-dashboard -n project-dashboard

# Confirm restored revision status
kubectl rollout status deployment/project-dashboard -n project-dashboard
```

---

## 4. Production AWS Deployment (Terraform & EKS)

### Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```

### Step 2: Generate Execution Plan
```bash
terraform plan -out=tfplan
```

### Step 3: Apply Infrastructure (Authorized Environments Only)
> [!IMPORTANT]
> Do not apply against paid AWS infrastructure without explicit stakeholder authorization.

```bash
terraform apply tfplan
```

### Step 4: Configure Kubeconfig for AWS EKS
```bash
aws eks update-kubeconfig --region ap-south-1 --name project-management-dev-eks
```

### Step 5: Deploy Application Manifests
```bash
kubectl apply -f k8s/project-dashboard.yaml
```

---

## 5. Automated Continuous Deployment (CD Pipeline)

The repository provides `.github/workflows/cd.yml` supporting automated deployments on `push: [main]` or manual trigger via `workflow_dispatch`:

1. **Pre-Flight Authentication Validation:**
   - Evaluates availability of `secrets.AWS_ROLE_ARN` before initiating runner workflows.
   - Halts pipeline execution with a clear diagnostic error (`::error::AWS_ROLE_ARN secret is not configured`) if credentials are absent, preventing misleading false-positive build passes.
2. **Build, SBOM & Verification:**
   - Generates immutable Git SHA image tag (`${{ github.sha }}`) and extracts the canonical sha256 registry digest.
   - Generates SPDX-JSON SBOM artifact for supply chain provenance.
   - Scans image with Trivy (blocking High/Critical CVEs with exit-code 1).
   - Packages verified image tarball.
3. **Deploy Job & Cluster Access:**
   - Authenticates to AWS via GitHub OIDC without long-lived static secrets.
   - Pushes image to Amazon ECR and deploys via immutable digest (`@sha256:...`) to eliminate tag-mutability drift.
   - Executes deployment within VPC via ephemeral Actions Runner Controller (ARC) on EKS (see [DEPLOYMENT_NETWORK_ARCHITECTURE.md](DEPLOYMENT_NETWORK_ARCHITECTURE.md)).
   - Updates EKS deployment image digest.
4. **Post-Deployment Health & Automated Rollback:**
   - Waits for rollout completion (`kubectl rollout status --timeout=120s`).
   - Verifies condition `Available` and checks that ready replicas match desired replicas.
   - Executes in-cluster probe (`curl -s -f http://project-dashboard.project-dashboard.svc.cluster.local:80/health`).
   - On deployment failure, captures rollout history, automatically invokes `kubectl rollout undo deployment/project-dashboard`, waits for restored stability, confirms health of restored pods, and sets `rollback_status`.
   - Publishes detailed step summary report to GitHub Actions console.
