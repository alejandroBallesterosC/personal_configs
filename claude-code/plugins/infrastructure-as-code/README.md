# Infrastructure as Code Plugin

Terraform and AWS infrastructure management with safety-first practices.

```
/plugin install infrastructure-as-code --marketplace alejandroBallesterosC/personal_configs
```

## Components

- **1 user-invoked skill** (`update-terraform`): Sync Terraform code with current infrastructure state
- **1 auto-activating skill** (`infrastructure-as-code`): Best practices for Terraform and AWS management

## User-invoked skill

| Skill | Purpose |
|-------|---------|
| `/infrastructure-as-code:update-terraform` | Review all Terraform code and ensure infrastructure is reproducible and state is in sync |

`update-terraform` sets `disable-model-invocation: true`: it runs Terraform against live infrastructure, so it only runs when you type it. It:
1. Reviews all Terraform code and workflow documentation in the repo
2. Ensures infrastructure is fully reproducible from the Terraform code
3. Verifies state sync so cloning the repo and running Terraform commands creates no unintended changes, using a clean `terraform plan` per environment as the done check
4. Follows the `infrastructure-as-code` safety gate: plan before apply, surface destructive operations, explicit confirmation before changing live infrastructure

## Auto-activating skill

The `infrastructure-as-code` skill auto-activates when:
- Creating or modifying Terraform files (`*.tf`)
- Deploying AWS resources
- Managing infrastructure state

It provides best practices for safety, review-before-apply workflows, S3-native state locking, and environment separation.
