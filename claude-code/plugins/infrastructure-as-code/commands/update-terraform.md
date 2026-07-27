---
description: Audit this repo's Terraform against the live infrastructure and reconcile the two safely
---

Thoroughly review all of the terraform code and terraform workflow documentation for sharing state and collaborating with others in this repo. Then ensure all of the infrastructure tied to this repo is reproducible with the terraform code in it. If this is not the case, update the terraform code as necessary to reproduce the current infrastructure. The terraform code in this repo should be fully in sync with the current state of the infrastructure. Additionally, an engineer should be able to clone this repo, sync the terraform state through the specified workflow, and obtain the correct current state such that no unintended resources are created or destroyed when they run terraform commands. When you run terraform commands needed to do this, please be very careful that no unintended resources will be created or destroyed.

Follow the `infrastructure-as-code` skill's safety gate throughout: plan before any apply, surface every destructive operation for review, and get explicit confirmation before changing live infrastructure.
