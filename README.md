# Project Management Dashboard — DevOps Platform Project

A React and Vite project-management dashboard packaged and operated as a production-style DevOps project. The application remains a static frontend; this repository adds the delivery, deployment, infrastructure, and observability components around it.

## What this project demonstrates

- **Docker:** multi-stage build creates a small Nginx production image.
- **Linux/Nginx operations:** Nginx serves the SPA, provides a health endpoint, and exposes local status data for metrics collection.
- **CI/CD:** GitHub Actions runs linting and production builds, builds the image, smoke-tests `/health`, scans the image with Trivy, and validates Terraform.
- **Kubernetes:** deployment manifest includes two replicas, readiness and liveness probes, resource requests/limits, a service, metrics endpoint, and CPU-based autoscaling.
- **Terraform and AWS:** infrastructure as code provisions an immutable Amazon ECR image repository, lifecycle policy, scan-on-push, and CloudWatch log group.
- **Monitoring:** Prometheus scrapes Nginx metrics through the official Nginx Prometheus exporter.

## Architecture

```
Developer push / pull request
          |
          v
 GitHub Actions: lint → build → Docker smoke test → Trivy scan → Terraform validate
          |
          v
 Amazon ECR (created by Terraform)
          |
          v
 Kubernetes Deployment (2+ replicas)
          |
          +--> Nginx health probes
          +--> Nginx Prometheus exporter --> Prometheus
```

## Run locally

### Application only

```bash
npm ci
npm run dev
```

### Full local observability stack

```bash
docker compose up --build
```

Open:

- Dashboard: http://localhost:8080
- Health check: http://localhost:8080/health
- Prometheus metrics: http://localhost:9113/metrics
- Prometheus UI: http://localhost:9090

Stop the stack with:

```bash
docker compose down
```

## CI/CD

The workflow in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs for pull requests and pushes to `main`. It deliberately stops before cloud deployment because this public repository does not contain cloud credentials.

To add a deployment stage later, configure GitHub OIDC with AWS and grant only the required ECR and Kubernetes permissions. Do not store long-lived AWS keys in the repository.

## Provision AWS resources

Terraform configuration lives in `terraform/`. It creates an ECR repository with immutable tags and scan-on-push, a lifecycle policy that retains the newest 10 images, and a CloudWatch log group.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This requires AWS credentials with permission to create ECR repositories, lifecycle policies, and CloudWatch log groups. After applying, tag and push the Docker image to the `ecr_repository_url` Terraform output.

## Deploy to Kubernetes

1. Build and push the image to the ECR URL created by Terraform.
2. Replace `REPLACE_WITH_YOUR_ECR_IMAGE` in `k8s/project-dashboard.yaml`.
3. Apply the manifest:

```bash
kubectl apply -f k8s/project-dashboard.yaml
kubectl get pods -n project-dashboard
```

The HPA needs Metrics Server in the target cluster. The Prometheus annotations assume a Prometheus installation that discovers annotated services.

## Resume-ready description

**Project Management Dashboard — DevOps Platform**

Containerized a React dashboard using multi-stage Docker and Nginx; built GitHub Actions CI for linting, production builds, container smoke tests, vulnerability scanning, and Terraform validation. Created Kubernetes manifests with health probes, autoscaling, resource limits, and Prometheus metrics; authored Terraform for an AWS ECR registry and CloudWatch log group.

## Application technology

React, Vite, JavaScript, CSS, and Lucide React.
