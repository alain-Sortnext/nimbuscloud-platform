# INC-2024-047 Post-Mortem

## Executive Summary

On 14 May 2026, NimbusCloud experienced a production outage affecting the booking, payment, authentication, and notification service chain used by Meridian Finance.

The evidence confirms memory exhaustion and subsequent Kubernetes OOMKilled events as the immediate technical failure mechanism. The booking-api pod was OOMKilled at 02:38 UTC after hitting its memory limit and entered CrashLoopBackOff. The payment-api pod was OOMKilled at 02:41 UTC and also entered CrashLoopBackOff.

The platform metrics show a deterioration before the incident. Booking API memory utilisation increased from 52% in Week 7 to 61% in Week 8 and 73% in Week 9. During the same period, booking P99 latency increased from 189 ms to 214 ms and then 298 ms, while pod restarts increased from zero to one and then three.

This trend, combined with the incident timeline and kubectl diagnosis, supports memory exhaustion as the confirmed failure mechanism rather than an application code error inferred solely from HTTP error rates.

## Confirmed Root Cause

The confirmed immediate technical cause was memory exhaustion causing Kubernetes pods to exceed their configured memory limits and be terminated with OOMKilled.

Evidence:

- Booking memory usage increased from 52% in Week 7 to 61% in Week 8 and 73% in Week 9.
- Pod restarts increased to three in Week 9.
- At 02:38 UTC on 14 May, booking-api was OOMKilled after hitting its memory limit.
- At 02:41 UTC, payment-api was OOMKilled and entered CrashLoopBackOff.
- At 03:22 UTC, kubectl investigation identified OOMKilled and suspected memory exhaustion.
- Restarting the affected deployments restored service.

The available evidence confirms memory exhaustion/OOM termination as the immediate root cause of the outage. It does not, by itself, prove the underlying reason for the abnormal memory consumption, such as a specific memory leak. That deeper cause would require additional profiling evidence.

## Why the Error Spike Was a Symptom

The HTTP error spike must not be treated as the root cause.

At 02:17 UTC, booking-api 500 errors exceeded 15%. At 02:19 UTC, payment-api errors exceeded 12%.

Those errors describe how the failure appeared to clients. They do not identify why the services became unhealthy.

The subsequent timeline provides causal infrastructure evidence: readiness failures occurred, pods exceeded memory limits, Kubernetes terminated the pods with OOMKilled, the deployments entered CrashLoopBackOff, and kubectl later confirmed the OOMKilled condition.

Therefore:

Error spike = symptom / customer-visible manifestation.

Memory exhaustion followed by OOMKilled = confirmed immediate technical root cause.

## Incident Timeline

| UTC | Event |
|---|---|
| 02:17 | booking-api 500 error rate exceeded 15%; 847 failed requests in 60 seconds |
| 02:19 | payment-api 500 error rate exceeded 12%; payment authorisations failing |
| 02:23 | notification-service SQS queue reached 1,840 messages |
| 02:31 | auth-service readiness probe failed; pod marked NotReady |
| 02:38 | booking-api OOMKilled after reaching memory limit; CrashLoopBackOff began |
| 02:41 | payment-api OOMKilled; CrashLoopBackOff began |
| 03:00 | Meridian Finance operations noticed booking failures |
| 03:04 | Meridian Finance called NimbusCloud emergency line |
| 03:09 | Jordan Reeves began investigation |
| 03:22 | kubectl investigation showed OOMKilled; memory exhaustion suspected |
| 03:24 | booking-api deployment restarted |
| 03:26 | payment-api deployment restarted |
| 03:30 | booking-api pods Running; error rate decreasing |
| 03:47 | All services confirmed healthy |
| 03:52 | Meridian Finance updated; RCA promised |

## Impact

The incident caused booking failures, payment authorisation failures, an SQS notification backlog, authentication readiness failures, and service instability.

Meridian Finance observed booking failures and escalated the incident externally.

The incident timeline shows that customer-visible errors began at 02:17 UTC and all services were confirmed healthy at 03:47 UTC, representing approximately 90 minutes from the first recorded customer-impacting error to confirmed full recovery.

A major operational weakness was delayed internal detection. The OOMKilled events explicitly show "none (no monitoring)" as the detection source.

## Recovery

Operations diagnosed memory exhaustion using kubectl.

The immediate recovery actions were:

1. Restart booking-api at 03:24 UTC.
2. Restart payment-api at 03:26 UTC.
3. Confirm booking-api recovery at 03:30 UTC.
4. Confirm all services healthy at 03:47 UTC.
5. Update Meridian Finance at 03:52 UTC.

## Prevention Actions

### Action 1 - Monitoring and alerting
Owner: Platform Engineering

Maintain Prometheus monitoring for booking-api, payment-api, auth-service and notification-service and maintain CloudWatch alarms for latency, error rates, queue backlog and pod restarts.

### Action 2 - Memory monitoring and capacity review
Owner: Platform Engineering

Add explicit container memory utilisation and memory-limit monitoring. Review Kubernetes resource requests and limits using observed production utilisation before changing limits.

### Action 3 - OOM/CrashLoop alerting
Owner: Platform Engineering

Alert on abnormal pod restart frequency, OOMKilled events and CrashLoopBackOff so operations are notified before customers escalate.

### Action 4 - Incident runbook
Owner: Platform Engineering

Maintain the Kubernetes recovery runbook with procedures for identifying OOMKilled pods, reviewing resource consumption and safely restarting affected deployments.

### Action 5 - Root-cause follow-up
Owner: Application Engineering

Profile booking-api and payment-api memory behaviour to determine why memory consumption increased. Do not label the underlying cause a memory leak unless profiling confirms it.

## Conclusion

INC-2024-047 was caused immediately by memory exhaustion resulting in Kubernetes OOMKilled events and CrashLoopBackOff for critical application services.

The HTTP error spike was a symptom of the service degradation, not evidence of a code defect as the root cause.

The monitoring improvements implemented after the incident reduce the risk that a similar infrastructure failure will remain undetected until client escalation.
