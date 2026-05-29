# Incident Report — INC-2024-047 (PRELIMINARY — POST-MORTEM NOT WRITTEN)
## Status: OPEN — Root cause investigation incomplete

---

**Incident ID:** INC-2024-047
**Severity:** P1 — Production down
**Date:** 14 May 2026
**Start time:** 02:17 UTC
**End time:** 03:04 UTC
**Duration:** 47 minutes
**Detected by:** Client call (Meridian Finance operations team)
**Resolved by:** Jordan Reeves (on-call), manual pod restart

---

## Impact

| Metric | Value |
|---|---|
| Services affected | booking-api, payment-api |
| Clients affected | All 140+ clients |
| Booking requests failed | ~3,200 (estimated) |
| Payment attempts failed | ~890 (estimated) |
| SLA breach | YES — 47 min exceeds 30-min SLA |
| SLA penalty issued | £18,000 |
| Churn risk triggered | Meridian Finance, Crestfield Retail |

---

## Timeline

| Time (UTC) | Event |
|---|---|
| 02:17 | First error logs in booking-api (not alerted — no monitoring) |
| 02:19 | payment-api begins returning 500s |
| 02:23 | SQS queue depth begins spiking — notification backlog grows |
| 02:31 | auth-service readiness probe begins failing |
| ~03:00 | Meridian Finance operations team notices booking failures |
| 03:04 | Meridian Finance calls NimbusCloud emergency line |
| 03:09 | Jordan Reeves paged — manual investigation begins |
| 03:22 | Root cause identified as suspected: Kubernetes pod memory exhaustion |
| 03:24 | `kubectl rollout restart deployment/booking-api` |
| 03:26 | `kubectl rollout restart deployment/payment-api` |
| 03:28 | Pods back to Running state |
| 03:30 | Services recovering — error rate dropping |
| 03:47 | All services confirmed healthy |
| 03:52 | Meridian Finance updated — incident closed |

---

## Preliminary Root Cause

**Suspected:** Kubernetes pod memory limit hit — pods OOMKilled, entered CrashLoopBackOff  
**Actual root cause:** NOT CONFIRMED — no logs captured during outage window  
**Evidence gap:** Prometheus had no scrape targets — no metrics from 02:00–03:50 UTC  

> ⚠️ The actual root cause remains UNKNOWN because monitoring was not in place.
> This post-mortem is INCOMPLETE. A full post-mortem must be written.
> Assigned to: NEW CLOUD ENGINEER (you) — Phase 6

---

## Outstanding Actions

| # | Action | Owner | Due | Status |
|---|---|---|---|---|
| 1 | Write full post-mortem with confirmed root cause | Incoming cloud engineer | Phase 6 | OPEN |
| 2 | Implement Prometheus scrape targets | Incoming cloud engineer | Phase 5 | OPEN |
| 3 | Create Grafana dashboards for all 4 services | Incoming cloud engineer | Phase 5 | OPEN |
| 4 | Configure CloudWatch alarms for latency and errors | Incoming cloud engineer | Phase 5 | OPEN |
| 5 | Fix auth-service readiness probe | Incoming cloud engineer | Phase 2 | OPEN |
| 6 | Document memory limit recommendations | Incoming cloud engineer | Phase 7 | OPEN |

---

## Notes from Jordan Reeves (outgoing engineer)

> "I didn't have time to set up proper monitoring before the incident. The pod likely hit its memory limit — I've seen it happen before on high-traffic nights. The fix was a rollout restart but I can't prove it. The real problem is we have no visibility into what happened. Whoever inherits this needs to sort out Prometheus and Grafana before the next incident — not after it."
> — Jordan Reeves, 2026-05-01

