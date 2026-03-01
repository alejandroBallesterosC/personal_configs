# Infrastructure as Code Plugin

Terraform and AWS infrastructure management with safety-first practices.

## Components

- **1 command** (`update-terraform`): Sync Terraform code with current infrastructure state
- **1 skill** (`infrastructure-as-code`): Best practices for Terraform and AWS management

## Commands

| Command | Purpose |
|---------|---------|
| `/infrastructure-as-code:update-terraform` | Review all Terraform code and ensure infrastructure is reproducible and state is in sync |

The `update-terraform` command:
1. Reviews all Terraform code and workflow documentation in the repo
2. Ensures infrastructure is fully reproducible from the Terraform code
3. Verifies state sync so cloning the repo and running Terraform commands creates no unintended changes
4. Operates with extreme caution to prevent unintended resource creation or destruction

## Skill

The `infrastructure-as-code` skill auto-activates when:
- Creating or modifying Terraform files (`*.tf`)
- Deploying AWS resources
- Managing infrastructure state

It provides best practices for safety, review-before-apply workflows, and environment separation.

## Version

1.0.0
