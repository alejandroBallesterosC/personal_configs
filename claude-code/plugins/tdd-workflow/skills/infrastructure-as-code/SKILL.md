---
name: infrastructure-as-code
description: Best practices for Terraform and AWS infrastructure management. Use when creating, updating, or managing AWS infrastructure, writing Terraform code, or deploying cloud resources.
---

# Infrastructure as Code (Terraform + AWS)

Best practices for managing AWS infrastructure with Terraform. Emphasizes safety, review-before-apply, and environment separation.

## When to Activate

Activate when:
- Creating or modifying Terraform files (*.tf)
- Deploying AWS resources
- Managing infrastructure state
- Setting up new environments (dev/staging/prod)
- Discussing cloud architecture

**Announce at start:** "I'm using the infrastructure-as-code skill."

## CRITICAL SAFETY RULES

### The Golden Rule

```
NEVER run `terraform apply` without first running `terraform plan`
and having the user review ALL proposed changes.
```

### Before ANY Apply

1. **Run plan first**: `terraform plan -var-file=<env>.tfvars -out=plan.tfplan`
2. **Review the output** with the user
3. **Alert on destructive changes**: Look for `destroy`, `replace`, or `-/+` operations
4. **Explain impact**: What resources change, potential downtime, data loss risks
5. **Get explicit approval**: User must confirm before apply

### Destructive Change Alerts

**ALWAYS WARN** the user when plan shows:

| Symbol | Meaning | Risk Level |
|--------|---------|------------|
| `-/+` | Destroy and recreate | 🔴 HIGH - Data loss possible |
| `-` | Destroy | 🔴 HIGH - Resource deleted |
| `~` | Update in-place | 🟡 MEDIUM - Check what changes |
| `+` | Create | 🟢 LOW - New resource |

**Example warning:**
```markdown
⚠️ DESTRUCTIVE CHANGES DETECTED

The plan shows:
- 1 resource to DESTROY: aws_db_instance.main
- 2 resources to REPLACE: aws_ecs_service.api, aws_lambda_function.processor

This will cause:
- Database deletion (DATA LOSS if not backed up)
- Service downtime during replacement

Do you want to proceed? Please confirm explicitly.
```

## Directory Structure

### Standard Layout

```
infrastructure/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf          # Dev-specific resources
│   │   │   ├── terraform.tfvars # Dev variables (gitignored)
│   │   │   └── backend.tf       # Dev state backend
│   │   ├── staging/
│   │   │   └── ...
│   │   └── prod/
│   │       └── ...
│   │
│   ├── modules/                  # Reusable modules
│   │   ├── vpc/
│   │   ├── eks/
│   │   ├── rds/
│   │   └── ...
│   │
│   ├── main.tf                   # Root module
│   ├── providers.tf              # Provider configuration
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── versions.tf               # Terraform/provider versions
│   │
│   ├── terraform.tfvars.example  # Example variables (committed)
│   └── terraform.tfvars          # Actual values (gitignored)
│
├── manifests/                    # Kubernetes manifests (if using K8s)
│   ├── base/
│   └── overlays/
│       ├── dev/
│       └── prod/
│
└── docs/
    ├── INFRASTRUCTURE.md
    └── RUNBOOK.md
```

### Alternative: Workspace-Based

```
infrastructure/
├── terraform/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   │
│   ├── dev.tfvars               # terraform workspace select dev
│   ├── staging.tfvars           # terraform workspace select staging
│   └── prod.tfvars              # terraform workspace select prod
```

### File Header Convention

Every .tf file should start with ABOUTME comment:

```hcl
# ABOUTME: EKS cluster configuration with private endpoint
# ABOUTME: Includes OIDC provider for IRSA, managed node groups
```

## State Management

### Remote State Setup (REQUIRED)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "project/environment/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### State Backend Resources

```hcl
# Create these ONCE, manually or via separate terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "company-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### State Lock Handling

```bash
# Check if terraform is running elsewhere
ps aux | grep terraform

# View lock info
terraform state pull | jq '.lineage'

# Force unlock ONLY if certain no other process running
terraform force-unlock <lock-id>
```

## Environment Separation

### Variable Files Per Environment

```hcl
# dev.tfvars
environment = "dev"
instance_type = "t3.small"
min_nodes = 1
max_nodes = 2
enable_deletion_protection = false

# prod.tfvars
environment = "prod"
instance_type = "m6i.large"
min_nodes = 2
max_nodes = 10
enable_deletion_protection = true
```

### Conditional Resources

```hcl
# Only create in dev
resource "aws_instance" "bastion" {
  count = var.environment == "dev" ? 1 : 0
  # ...
}

# Different config per environment
resource "aws_rds_cluster" "main" {
  deletion_protection = var.environment == "prod" ? true : false
  # ...
}
```

## Standard Workflow

### Daily Operations

```bash
# 1. Initialize (first time or after backend changes)
cd infrastructure/terraform
terraform init

# 2. Select workspace (if using workspaces)
terraform workspace select dev

# 3. ALWAYS plan first
terraform plan -var-file=dev.tfvars -out=plan.tfplan

# 4. Review plan output carefully

# 5. Apply only after review
terraform apply plan.tfplan

# 6. Verify in AWS console
```

### Making Changes

```bash
# 1. Edit .tf files
# 2. Format
terraform fmt -recursive

# 3. Validate syntax
terraform validate

# 4. Plan and review
terraform plan -var-file=dev.tfvars

# 5. Apply
terraform apply -var-file=dev.tfvars
```

### Targeted Operations

```bash
# Apply only specific resources (ONLY USE WHEN ABSOLUTELY NECESSARY)
terraform apply -target=aws_iam_role.api_role -var-file=dev.tfvars

# Refresh state without changes
terraform apply -refresh-only -var-file=dev.tfvars

# Import existing resource
terraform import aws_s3_bucket.data my-existing-bucket
```

## Security Best Practices

### NEVER COMMIT

```gitignore
# .gitignore
*.tfvars           # Contains secrets
!*.tfvars.example  # Keep examples
*.tfstate          # State files
*.tfstate.*
.terraform/        # Provider cache
*.tfplan           # Plan files
```

### Secrets Handling

```hcl
# Create empty secret, populate manually
resource "aws_secretsmanager_secret" "api_key" {
  name = "${var.project}-api-key"
}

# Reference in other resources
data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id
}
```

### IAM Least Privilege

```hcl
# Specific permissions, not wildcards
resource "aws_iam_policy" "s3_read" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.data.arn,
        "${aws_s3_bucket.data.arn}/*"
      ]
    }]
  })
}
```

## Common Patterns

### Naming Convention

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_s3_bucket" "data" {
  bucket = "${local.name_prefix}-data-${data.aws_caller_identity.current.account_id}"
}
```

### Tags

```hcl
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "github.com/company/repo"
  }
}

resource "aws_instance" "app" {
  # ...
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-app"
  })
}
```

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Error acquiring state lock" | Another terraform running | Wait or `force-unlock` |
| "ResourceAlreadyExists" | Resource exists but not in state | `terraform import` |
| "InvalidParameterValue" | Wrong parameter | Check AWS docs for valid values |
| "AccessDenied" | Missing IAM permissions | Add required permissions |

### Debugging

```bash
# Enable debug logging
TF_LOG=DEBUG terraform plan

# Check AWS credentials
aws sts get-caller-identity

# Inspect state
terraform state list
terraform state show aws_instance.app

# Check for drift
terraform plan -refresh-only
```

### Rule of Thumb (When Using Kubernetes)

```
Infrastructure in Terraform → Applications in Kubernetes manifests
```

## Quick Reference

### Essential Commands

```bash
terraform init              # Initialize
terraform fmt -recursive    # Format all files
terraform validate          # Check syntax
terraform plan -out=p.tfplan -var-file=dev.tfvars  # Plan
terraform apply p.tfplan    # Apply saved plan
terraform destroy           # Destroy (CAREFUL!)
```

### Before Committing

- [ ] `terraform fmt` passes
- [ ] `terraform validate` passes
- [ ] Plan reviewed, no unexpected changes
- [ ] Tested in dev environment
- [ ] Documentation updated if needed
- [ ] No secrets in committed files
