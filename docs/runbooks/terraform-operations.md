# Runbook: Terraform Operations
## NimbusCloud Platform — Platform Engineering Team
**Last updated:** 2026-04-20 (Jordan Reeves)

---

## Standard Terraform Workflow

```bash
cd infrastructure/terraform

# 1. Always check state before making changes
terraform init
terraform plan

# 2. Review the plan carefully — look for unexpected destroy/replace
# 3. Apply only if plan looks correct
terraform apply

# 4. If applying to production — always use -target first to scope changes
terraform apply -target=aws_s3_bucket.assets
```

---

## Current State Issues

Running `terraform plan` will show errors:
1. **Missing variables** — `environment` and `bucket_suffix` not in terraform.tfvars
2. **Wrong output reference** — `outputs.tf` references `aws_lb.nimbuscloud_alb` which was renamed to `aws_lb.main`

Fix both before running apply.

---

## State Drift

If AWS resources were changed outside Terraform (console or CLI), state drift occurs.

```bash
# See what Terraform thinks vs what exists
terraform plan

# Import an existing resource into state (if it was created outside Terraform)
terraform import aws_s3_bucket.assets nimbuscloud-platform-assets-prod-123456789012

# Remove a resource from state without destroying it (if intentionally unmanaged)
terraform state rm aws_resource.name
```

---

## Destroy (emergency only)

```bash
# DANGEROUS — destroys all managed resources
# Get approval from Priya before running
terraform destroy

# Safer: destroy a specific resource
terraform destroy -target=aws_instance.name
```

