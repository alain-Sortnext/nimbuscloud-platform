# NimbusCloud Platform — Architecture Overview

**Last updated:** 2026-05-01  
**Author:** Jordan Reeves (Cloud Engineer — departing)  
**Status:** ⚠️ PARTIALLY ACCURATE — network diagram not yet updated after VPC migration in March 2026

---

## System Overview

NimbusCloud operates a multi-tenant SaaS platform on AWS (eu-west-2). Four microservices handle distinct business domains. All client traffic enters via an Application Load Balancer (ALB).

```
                        ┌─────────────────────────────┐
                        │         INTERNET             │
                        └──────────────┬──────────────┘
                                       │ HTTPS :443
                                       ▼
                        ┌─────────────────────────────┐
                        │   Application Load Balancer  │
                        │   nimbuscloud-alb            │
                        │   alb-sg: 0.0.0.0/0 → 443   │
                        └──────┬──────────────┬────────┘
                               │              │
               ┌───────────────┘              └──────────────┐
               ▼                                             ▼
  ┌─────────────────────────┐              ┌─────────────────────────┐
  │  Public Subnet AZ-a     │              │  Public Subnet AZ-b     │
  │  10.0.1.0/24            │              │  10.0.2.0/24            │
  │  eu-west-2a             │              │  eu-west-2b             │
  └───────────┬─────────────┘              └────────────┬────────────┘
              │ app-sg: alb-sg → 3001-3004               │
              ▼                                          ▼
  ┌─────────────────────────┐              ┌─────────────────────────┐
  │  Private Subnet AZ-a    │              │  Private Subnet AZ-b    │
  │  10.0.10.0/24           │              │  10.0.11.0/24           │
  │                         │              │                         │
  │  ┌──────────────────┐   │              │  ┌──────────────────┐   │
  │  │  booking-api     │   │              │  │  booking-api     │   │
  │  │  :3001           │   │              │  │  :3001           │   │
  │  ├──────────────────┤   │              │  ├──────────────────┤   │
  │  │  payment-api     │   │              │  │  payment-api     │   │
  │  │  :3002           │   │              │  │  :3002           │   │
  │  ├──────────────────┤   │              │  ├──────────────────┤   │
  │  │  auth-service    │   │              │  │  auth-service    │   │
  │  │  :3003           │   │              │  │  :3003           │   │
  │  ├──────────────────┤   │              │  ├──────────────────┤   │
  │  │  notification-   │   │              │  │  notification-   │   │
  │  │  service :3004   │   │              │  │  service :3004   │   │
  │  └──────────────────┘   │              │  └──────────────────┘   │
  └───────────┬─────────────┘              └────────────┬────────────┘
              │ data-sg: app-sg → 443/8080               │
              ▼                                          ▼
  ┌──────────────────────────────────────────────────────────────────┐
  │                        DATA TIER                                  │
  │                                                                   │
  │   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
  │   │  DynamoDB        │  │  S3 Bucket       │  │  SQS Queue      │ │
  │   │  nimbuscloud-    │  │  nimbuscloud-    │  │  nimbuscloud-   │ │
  │   │  sessions        │  │  platform-assets │  │  notifications- │ │
  │   │                  │  │  ⚠️ PUBLIC ACL   │  │  queue          │ │
  │   └─────────────────┘  └─────────────────┘  └────────┬────────┘ │
  │                                                        │          │
  │                                              ┌─────────▼────────┐ │
  │                                              │  Lambda Function  │ │
  │                                              │  notification-    │ │
  │                                              │  dispatcher       │ │
  │                                              └──────────────────┘ │
  └──────────────────────────────────────────────────────────────────┘
```

---

## Security Group Rules

### alb-sg (Application Load Balancer)
| Direction | Protocol | Port | Source | Reason |
|---|---|---|---|---|
| Inbound | HTTPS | 443 | 0.0.0.0/0 | Client traffic |
| Inbound | HTTP | 80 | 0.0.0.0/0 | Redirect to HTTPS |
| Outbound | All | All | 0.0.0.0/0 | ALB to targets |

### app-sg (Application Tier)
| Direction | Protocol | Port | Source | Reason |
|---|---|---|---|---|
| Inbound | TCP | 3001-3004 | alb-sg | Service ports |
| Inbound | TCP | 9090 | app-sg | Prometheus scrape |
| Outbound | HTTPS | 443 | 0.0.0.0/0 | AWS API calls |
| Outbound | TCP | 443/8080 | data-sg | DynamoDB/S3 |

### data-sg (Data Tier — DynamoDB endpoints)
| Direction | Protocol | Port | Source | Reason |
|---|---|---|---|---|
| Inbound | HTTPS | 443 | app-sg | DynamoDB API |
| Outbound | All | All | 0.0.0.0/0 | VPC endpoints |

---

## Service Responsibilities

| Service | Owns | Depends On | SLA |
|---|---|---|---|
| booking-api | Booking CRUD, slot availability | DynamoDB (sessions table), auth-service | 99.9% |
| payment-api | Payment webhooks, Stripe authorisation | DynamoDB (sessions table), SQS | 99.95% |
| auth-service | JWT issuance, session validation | DynamoDB (sessions table), Secrets Manager | 99.99% |
| notification-service | Email/SMS dispatch | SQS (notifications-queue), Lambda | 99.5% |

---

## Known Architecture Debt

1. **No service mesh** — inter-service calls are direct HTTP, no mTLS
2. **Shared DynamoDB table** — all services write to `nimbuscloud-sessions` — needs partitioning
3. **No circuit breaker** — payment-api has no fallback when Stripe is slow
4. **S3 bucket public ACL** — needs immediate remediation (Fatima's finding)
5. **No VPC flow logs** — cannot audit network traffic

