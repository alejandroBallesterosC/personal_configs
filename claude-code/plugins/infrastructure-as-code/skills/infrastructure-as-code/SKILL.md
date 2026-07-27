---
name: infrastructure-as-code
description: Best practices for Terraform and AWS infrastructure management. Use when creating, updating, or managing AWS infrastructure, writing Terraform code, or deploying cloud resources.
---

# Infrastructure as Code (Terraform + AWS)

Managing AWS infrastructure with Terraform: safety, review before apply, and environment separation.

## The safety gate

**Never run `terraform apply` without first running `terraform plan` and having the user review all proposed changes.**

This is an interlock, not a style preference. The plan output is the only place a destructive change is visible before it happens.

1. Plan to a file: `terraform plan -var-file=<env>.tfvars -out=plan.tfplan`
2. Review the output with the user.
3. Call out destructive operations explicitly.
4. Explain the impact: which resources change, what downtime, what data loss is possible.
5. Get explicit confirmation, then `terraform apply plan.tfplan`.

Applying a saved plan file rather than re-planning at apply time is deliberate: it guarantees the user approved exactly what runs.

### Destructive change alerts

| Symbol | Meaning | Risk |
|--------|---------|------|
| `-/+` | Destroy and recreate | HIGH — data loss possible |
| `-` | Destroy | HIGH — resource deleted |
| `~` | Update in place | MEDIUM — check what changes |
| `+` | Create | LOW — new resource |

Warn in this shape, so the consequence is stated rather than left for the user to infer from resource names:

```markdown
DESTRUCTIVE CHANGES DETECTED

The plan shows:
- 1 resource to DESTROY: aws_db_instance.main
- 2 resources to REPLACE: aws_ecs_service.api, aws_lambda_function.processor

This will cause:
- Database deletion (DATA LOSS if not backed up)
- Service downtime during replacement

Do you want to proceed? Please confirm explicitly.
```

## Directory layout

Preferred structure, environment-per-directory:

```
infrastructure/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf          # Dev-specific resources
│   │   │   ├── terraform.tfvars # Dev variables (gitignored)
│   │   │   └── backend.tf       # Dev state backend
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/                  # Reusable modules (vpc, eks, rds, ...)
│   ├── main.tf                   # Root module
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf               # Terraform/provider versions
│   ├── terraform.tfvars.example  # Committed
│   └── terraform.tfvars          # Gitignored
├── manifests/                    # Kubernetes manifests, if using K8s
│   ├── base/
│   └── overlays/{dev,prod}/
└── docs/
    ├── INFRASTRUCTURE.md
    └── RUNBOOK.md
```

The workspace-based alternative (one root module, `dev.tfvars`/`staging.tfvars`/`prod.tfvars`, selected via `terraform workspace select`) is acceptable for smaller setups. Follow whichever the repo already uses.

Every `.tf` file starts with ABOUTME comments:

```hcl
# ABOUTME: EKS cluster configuration with private endpoint
# ABOUTME: Includes OIDC provider for IRSA, managed node groups
```

When using Kubernetes: infrastructure in Terraform, applications in Kubernetes manifests.

## State management

Remote state is required, with locking:

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

The backend resources themselves are created once, separately from the infrastructure that uses them — a bucket with `prevent_destroy = true` and versioning enabled, plus a DynamoDB table keyed on `LockID` for the lock. Versioning and `prevent_destroy` are what let you recover from a corrupted or truncated state file.

Only ever `terraform force-unlock` after confirming no other terraform process is running. A forced unlock during a live apply corrupts state.

## Environment separation

Vary environments through tfvars, not through separate copies of the code:

```hcl
# dev.tfvars
environment                = "dev"
instance_type              = "t3.small"
min_nodes                  = 1
max_nodes                  = 2
enable_deletion_protection = false

# prod.tfvars
environment                = "prod"
instance_type              = "m6i.large"
min_nodes                  = 2
max_nodes                  = 10
enable_deletion_protection = true
```

Gate environment-specific resources on `count = var.environment == "dev" ? 1 : 0` rather than commenting blocks in and out.

## Security

Never commit these:

```gitignore
*.tfvars           # Contains secrets
!*.tfvars.example  # Keep examples
*.tfstate
*.tfstate.*
.terraform/
*.tfplan
```

Create secrets as empty `aws_secretsmanager_secret` resources and populate the values out of band, so the value never enters state or version control.

Write IAM policies with specific actions and specific resource ARNs. No wildcards.

Name and tag from locals so the convention holds across the whole config:

```hcl
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "github.com/company/repo"
  }
}
```

## Workflow and troubleshooting

Making a change: edit, `terraform fmt -recursive`, `terraform validate`, plan, review, apply.

`-target` exists but should be a last resort — it applies a subset and leaves state partially converged. Use `terraform import` to bring an existing resource under management, and `terraform plan -refresh-only` to detect drift.

| Error | Cause | Fix |
|-------|-------|-----|
| Error acquiring state lock | Another terraform is running | Wait; `force-unlock` only if certain |
| ResourceAlreadyExists | Resource exists but is not in state | `terraform import` |
| AccessDenied | Missing IAM permissions | Add the required permissions |

For debugging: `TF_LOG=DEBUG terraform plan`, `aws sts get-caller-identity` to confirm which credentials are in play, and `terraform state list` / `terraform state show <addr>` to inspect state.

Before committing: `fmt` and `validate` pass, the plan was reviewed with no unexpected changes, the change was tested in dev, no secrets are in committed files, and the docs are updated if behavior changed.
