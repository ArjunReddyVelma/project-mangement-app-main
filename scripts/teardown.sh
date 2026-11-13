#!/usr/bin/env bash
# ==============================================================================
# Production Teardown & Decommissioning Script
# ==============================================================================
# Safely decommissions the Project Management Dashboard DevOps Platform.
# Enforces account verification, state backup preservation, and explicit confirmation.
# ==============================================================================
set -euo pipefail

DRY_RUN=false
PURGE_STATE=false

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --dry-run       Simulate teardown steps without modifying resources
  --purge-state   Also delete the remote S3 state bucket (REQUIRES SECOND CONFIRMATION)
  --help          Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --purge-state)
      PURGE_STATE=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

echo "=================================================================="
echo "⚠️  CRITICAL: INITIATING DEVOPS PLATFORM DECOMMISSIONING"
echo "=================================================================="

# Check AWS CLI availability
if ! command -v aws &>/dev/null; then
  echo "❌ Error: AWS CLI is not installed or not in PATH."
  exit 1
fi

# Verify AWS identity and credentials
echo "Verifying AWS authentication..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "UNAUTHENTICATED")
CURRENT_REGION="${AWS_REGION:-ap-south-1}"

if [ "$CURRENT_ACCOUNT" = "UNAUTHENTICATED" ]; then
  echo "❌ Error: No valid AWS credentials configured. Cannot proceed with teardown."
  exit 1
fi

echo "Connected AWS Account: ${CURRENT_ACCOUNT}"
echo "Target AWS Region:    ${CURRENT_REGION}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "🔍 DRY RUN MODE: Simulating teardown steps without executing destructive actions."
  echo "1. Would delete Kubernetes workloads in namespace 'project-dashboard'"
  echo "2. Would back up Terraform state to 'terraform/terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)'"
  echo "3. Would empty Amazon ECR repository 'project-management-dashboard'"
  echo "4. Would run 'terraform destroy' in terraform/ directory"
  if [ "$PURGE_STATE" = true ]; then
    echo "5. Would purge remote S3 state bucket and DynamoDB lock table"
  else
    echo "5. State storage will be PRESERVED (default safeguard)"
  fi
  echo "Dry run complete."
  exit 0
fi

# Mandatory Interactive Confirmation
read -r -p "Type 'CONFIRM-DESTRUCTION' to proceed with destroying infrastructure: " CONFIRM_INPUT
if [ "$CONFIRM_INPUT" != "CONFIRM-DESTRUCTION" ]; then
  echo "Operation aborted by user. No resources were modified."
  exit 1
fi

# Step 1: Remove Kubernetes Workloads
echo "Step 1: Deleting Kubernetes workloads..."
if command -v kubectl &>/dev/null; then
  kubectl delete -f k8s/project-dashboard.yaml --ignore-not-found=true || true
  kubectl delete -f k8s/base/ --ignore-not-found=true || true
fi

# Step 2: Backup Terraform State
echo "Step 2: Backing up Terraform state..."
BACKUP_FILE="terraform/terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)"
if [ -f "terraform/terraform.tfstate" ]; then
  cp "terraform/terraform.tfstate" "$BACKUP_FILE"
  echo "Local state backed up to: $BACKUP_FILE"
fi

# Step 3: Purge ECR Repository Images
echo "Step 3: Checking ECR images..."
REPO_NAME="project-management-dashboard"
if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$CURRENT_REGION" &>/dev/null; then
  echo "Purging images from repository: $REPO_NAME..."
  IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO_NAME" --region "$CURRENT_REGION" --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")
  if [ "$IMAGE_IDS" != "[]" ] && [ -n "$IMAGE_IDS" ]; then
    aws ecr batch-delete-image --repository-name "$REPO_NAME" --region "$CURRENT_REGION" --image-ids "$IMAGE_IDS" >/dev/null || true
  fi
fi

# Step 4: Execute Terraform Destroy
echo "Step 4: Executing Terraform destroy..."
(
  cd terraform
  terraform destroy -auto-approve
)

# Step 5: State Storage Preservation
if [ "$PURGE_STATE" = true ]; then
  echo ""
  echo "⚠️  WARNING: You requested --purge-state."
  read -r -p "Type 'DELETE-STATE-PERMANENTLY' to confirm purging S3 state bucket: " STATE_CONFIRM
  if [ "$STATE_CONFIRM" = "DELETE-STATE-PERMANENTLY" ]; then
    BUCKET_NAME="project-management-terraform-state-${CURRENT_ACCOUNT}-${CURRENT_REGION}"
    echo "Purging S3 state bucket: $BUCKET_NAME..."
    aws s3 rb "s3://${BUCKET_NAME}" --force || true
    echo "Deleting DynamoDB lock table..."
    aws dynamodb delete-table --table-name project-management-terraform-locks --region "$CURRENT_REGION" || true
  else
    echo "State purge cancelled. Remote state bucket preserved."
  fi
else
  echo ""
  echo "ℹ️  Remote S3 state bucket and DynamoDB lock table were PRESERVED for auditability."
  echo "   To purge state storage explicitly, re-run with --purge-state."
fi

echo "=================================================================="
echo "✅ Teardown completed successfully."
echo "=================================================================="
