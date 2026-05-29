# Platform Handover Notes
## From: Jordan Reeves → New Cloud Engineer
**Date:** 2026-05-01
**Status:** ⚠️ INCOMPLETE — ran out of time before departure

---

> Whoever reads this — I'm sorry I didn't get to finish this properly.
> I've tried to document what I know but some of this is from memory
> and I can't verify all of it. Where I've put CHECK THIS, I mean it.

---

## What I Managed to Document

### Infrastructure — Terraform

Terraform config is in `infrastructure/terraform/`. The state is partially drifted
because someone (Marcus? not sure) made manual changes to the ALB target groups in
the console in April. Run `terraform plan` before touching anything.

Two variables are missing from `terraform.tfvars` — I forgot to add them before leaving.
The plan will fail without them. Check `variables.tf` for which ones.

The outputs.tf has a bug — I renamed the ALB resource from `nimbuscloud_alb` to `main`
during the VPC migration in March but didn't update the output reference. NOT DOCUMENTED.
CHECK THIS — the output block will error on plan.

### Kubernetes — Services

All manifests in `infrastructure/kubernetes/`. Four services. Roughly 60% working.

**booking-api** — BROKEN. Pod is in CrashLoopBackOff. I think it's the ConfigMap key.
The deployment references `DB_HOST` but I think I named it `DATABASE_HOST` in the ConfigMap.
I was going to fix this — didn't get to it.

**payment-api** — BROKEN. The secret `payment-api-secrets` doesn't exist.
I created `nimbuscloud-secrets` but forgot to create the payment-api specific one.
You'll need to create it with the Stripe keys. Ask Priya for the test keys.

**auth-service** — PARTIALLY WORKING. Service starts but readiness probe fails.
Pretty sure the probe path is wrong — the service exposes `/healthz` but I may have
put `/health` in the deployment. CHECK THIS.

**notification-service** — WORKING but ingress is broken.
The ingress rule has port 3005 for notification-service but the service is on 3004.
I noticed it but hadn't fixed it.

### Stages 4-6 Not Documented

> ⚠️ NOT DOCUMENTED — I only had time for stages 1-3.
> CI/CD, monitoring, and security sections below are incomplete.

### CI/CD — GitHub Actions

Pipeline is in `.github/workflows/deploy.yml`. IT IS BROKEN. Do not merge to main
until it's fixed. Known issues:
- DOCKER_PASSWORD secret not added to repo settings
- ECR registry variable name is wrong (I changed secrets during the March migration and
  forgot to update the workflow)
- No lint or test step — I was going to add these
- Cluster name in the deploy step is wrong — I renamed the cluster

The old cluster name was `nimbuscloud-prod-old`. New name is `nimbuscloud-platform-cluster`.
CHECK THIS before the deploy step.

### Security — CRITICAL ISSUES

Fatima has flagged three CRITICAL findings. See `docs/data/security_findings.csv`.

1. **S3 public bucket** — I left public-read on the assets bucket from a demo we did
   in February. Never changed it back. Fatima found it. Fix this FIRST.

2. **Hardcoded password** — `services/auth-service/.env` has `DB_PASSWORD=Nimbus2024!`.
   This is a real production password. It's in git history now. It needs to go into
   AWS Secrets Manager and the auth-service code needs updating to fetch it at startup.
   Do NOT rotate the password until Secrets Manager is configured or auth will break.

3. **IAM wildcard** — the platform role has `Action: *`. I did this to get things working
   quickly and never tightened it. Fatima is not happy. It needs a proper least-privilege
   policy. The services actually need: S3 GetObject/PutObject, DynamoDB GetItem/PutItem/Query,
   SQS SendMessage/ReceiveMessage/DeleteMessage, Lambda InvokeFunction, SecretsManager GetSecretValue.
   That's it. Everything else should be removed.

### Monitoring — OPEN QUESTION

There is no monitoring. Prometheus is installed via docker-compose but the `scrape_configs`
in `prometheus.yml` is empty. No Grafana dashboards exist. The incident in Week 2 happened
because there were no alerts.

All four services expose `/metrics` on their service ports. Prometheus needs scrape targets
added for each one.

For CloudWatch alarms — we need at minimum:
- booking-api latency P99 > 500ms → alarm
- payment-api error rate > 1% → alarm
- SQS queue depth > 500 → alarm
- Pod restarts > 3 in 10 minutes → alarm

---

## Open Questions (I couldn't answer before leaving)

1. What is the correct ECR registry URL? I changed it in March but didn't update everything.
   Ask Priya — she has the AWS account details.

2. Why did the booking-api memory usage start spiking in Week 7 (see platform_metrics_weekly.csv)?
   I suspect a memory leak in the DynamoDB query loop but never confirmed it.
   The incident in Week 8 may be related.

3. Is the DynamoDB table properly backed up? PITR is enabled but I never tested recovery.

---

## Contacts

| Name | Role | What they know |
|---|---|---|
| Priya Menon | Head of Platform Engineering | AWS account details, ECR registry URL, client SLA requirements |
| Fatima Al-Rashid | Security | SEC-findings detail, what she needs for sign-off |
| Marcus Webb | CTO | Why Meridian Finance matters, what he needs for Week 8 |

---

*Good luck — I'm sorry I left it in this state.*
*— Jordan*

