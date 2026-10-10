---
name: update-terraform
description: Audit this repo's Terraform against the live infrastructure and reconcile the two safely, so the code reproduces what is deployed and a fresh clone plans no unintended changes. User-invoked only.
disable-model-invocation: true
effort: high
---

Thoroughly review all of the Terraform code in this repo, and the Terraform workflow documentation for sharing state and collaborating with others. Then make sure all of the infrastructure tied to this repo is reproducible from that code. Where it is not, update the Terraform code until it reproduces the current infrastructure.

The goal is that the code and the live infrastructure are fully in sync, and that an engineer can clone this repo, sync the Terraform state through the documented workflow, and run Terraform commands without creating or destroying anything unintended. The check that shows this is done: for each environment, `terraform plan` against the live infrastructure reports no changes, and any remaining difference is one the user has reviewed and accepted.

Running Terraform commands is how you get there, and a wrong apply can destroy live resources, so follow the `infrastructure-as-code` skill's safety gate throughout: plan before any apply, surface every destructive operation for review, and get explicit confirmation before changing live infrastructure.
