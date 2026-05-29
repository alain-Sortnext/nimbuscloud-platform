# NimbusCloud Platform

Internal engineering repository for NimbusCloud Platforms Ltd — cloud-hosted SaaS infrastructure for 140+ enterprise clients.

**AWS Region:** eu-west-2 (London)  
**Environment:** Production + Staging  
**Last updated:** 2026-05-01 (Jordan Reeves — prior to departure)

---

## ⚠️ KNOWN ISSUES — CURRENT STATE

> This section was partially completed during handover. See `docs/incidents/` for full incident history.

| Issue | Severity | Status |
|---|---|---|
| booking-api pod CrashLoopBackOff | HIGH | OPEN |
| payment-api missing Secret | HIGH | OPEN |
| auth-service readiness probe failure | MEDIUM | OPEN |
| S3 bucket public ACL | CRITICAL | OPEN — Fatima flagged |
| IAM role wildcard permissions | CRITICAL | OPEN — Fatima flagged |
| Hardcoded DB_PASSWORD in auth-service | CRITICAL | OPEN |
| GitHub Actions pipeline broken | HIGH | OPEN |
| No Grafana dashboards | HIGH | OPEN |
| No CloudWatch alarms | HIGH | OPEN |

---

## Repository Structure

```
nimbuscloud-platform/
├── services/
│   ├── booking-api/          # Node.js — port 3001
│   ├── payment-api/          # Python — port 3002
│   ├── auth-service/         # Go — port 3003
│   └── notification-service/ # Node.js — port 3004
├── infrastructure/
│   ├── terraform/            # AWS IaC — S3, DynamoDB, IAM, VPC
│   ├── kubernetes/           # Manifests — deployments, services, ingress
│   ├── monitoring/           # Prometheus config + Grafana dashboards
│   └── scripts/              # Operational runscripts
├── .github/
│   └── workflows/            # GitHub Actions CI/CD
├── docs/
│   ├── incidents/            # Incident reports and post-mortems
│   ├── runbooks/             # Operational runbooks
│   ├── dashboards/           # Dashboard specs
│   └── data/                 # Platform metrics exports
├── docker-compose.yml
├── architecture.md
├── .env.example
└── README.md
```

---

## Quick Start (Local Development)

### Prerequisites
- Docker Desktop
- Minikube
- kubectl
- Terraform >= 1.5
- AWS CLI configured (`aws configure`)
- Node.js >= 18, Python >= 3.11, Go >= 1.21

### Start local environment

```bash
# Copy environment variables
cp .env.example .env
# Edit .env — fill in your AWS credentials and secrets

# Start all services locally
docker compose up --build

# Verify services
curl http://localhost:3001/healthz   # booking-api
curl http://localhost:3002/healthz   # payment-api
curl http://localhost:3003/healthz   # auth-service
curl http://localhost:3004/healthz   # notification-service
```

### Deploy to Kubernetes (local Minikube)

```bash
cd infrastructure/kubernetes
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml    # NOTE: secret.yaml is currently a template — see known issues
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

### Deploy infrastructure (Terraform)

```bash
cd infrastructure/terraform
terraform init
terraform plan   # Review before applying
terraform apply
```

> ⚠️ `terraform plan` currently shows errors — see known issues above.

---

## Team Contacts

| Name | Role | Contact |
|---|---|---|
| Priya Menon | Head of Platform Engineering | priya.menon@nimbuscloud.io |
| Jordan Reeves | Cloud Engineer (departing) | jordan.reeves@nimbuscloud.io |
| Fatima Al-Rashid | Head of Security & Compliance | fatima.alrashid@nimbuscloud.io |
| Marcus Webb | CTO | marcus.webb@nimbuscloud.io |

---

## Git Workflow

All changes must follow the PR workflow:

```bash
git checkout -b phase-N-description
# make changes
git add .
git commit -m "phase N: description of change"
git push origin phase-N-description
# Open PR on GitHub — do NOT push directly to main
```

Direct pushes to `main` are blocked.

---

## Related Documents

- [Architecture Overview](architecture.md)
- [Incident INC-2024-047](docs/incidents/INC-2024-047-preliminary.md)
- [Runbook: Kubernetes Recovery](docs/runbooks/kubernetes-recovery.md)
- [Platform Metrics Export](docs/data/)

