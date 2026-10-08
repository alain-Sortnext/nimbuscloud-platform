# Phase 7 - 5-Minute Meridian Finance Technical Walkthrough

Good morning, and thank you for the opportunity to present the findings from our investigation into incident INC-2024-047.

I will cover four areas: what happened, the confirmed root cause, what we are doing to prevent recurrence, and our current production-readiness position.

First, the incident.

The first recorded customer-impacting event occurred at 02:17 UTC on 14 May, when the booking API 500 error rate exceeded 15 percent, producing 847 failed requests in sixty seconds.

At 02:19, payment API errors exceeded 12 percent.

At 02:23, the notification queue reached 1,840 messages, and at 02:31 the authentication service failed its readiness probe.

The key infrastructure evidence appeared shortly afterward.

At 02:38, Kubernetes terminated the booking API pod with an OOMKilled condition after the pod reached its memory limit. It then entered CrashLoopBackOff.

At 02:41, the payment API was also OOMKilled and entered CrashLoopBackOff.

Operations began investigation after the client escalation, and at 03:22 kubectl confirmed the OOMKilled condition and pointed to memory exhaustion.

The booking and payment deployments were restarted at 03:24 and 03:26. Booking was recovering by 03:30, and all services were confirmed healthy at 03:47.

We cross-referenced this timeline with the historical platform metrics.

Booking API memory usage had increased from 52 percent in Week 7 to 61 percent in Week 8 and 73 percent in Week 9. During that deterioration, booking P99 latency increased from 189 milliseconds to 214 and then 298 milliseconds, while pod restarts increased to three.

This supports the incident evidence that memory pressure was building before the outage.

An important distinction is the error-rate spike.

The spike is not the root cause. It is the customer-visible symptom of services becoming unhealthy. The causal infrastructure evidence is the memory-limit breach, the OOMKilled events, CrashLoopBackOff, and the kubectl diagnosis.

Therefore, the confirmed immediate technical root cause is memory exhaustion resulting in Kubernetes OOMKilled termination.

We are deliberately not claiming that a specific memory leak caused the increased consumption because the available evidence does not prove that. Application profiling is required to establish the deeper reason memory usage increased.

For prevention, we have several actions.

First, the platform now has Prometheus monitoring across the four application services, a Grafana operational dashboard, and CloudWatch alarm configurations.

Second, memory utilisation and OOM conditions should be explicitly monitored so the operations team receives an alert before customers experience a prolonged outage.

Third, Kubernetes resource requests and limits should be reviewed using actual production utilisation.

Fourth, the recovery runbook should include OOMKilled and CrashLoopBackOff procedures.

Fifth, application engineering should profile the booking and payment services to determine the underlying reason for the memory growth.

We also reviewed cloud expenditure.

The three largest optimisation opportunities provide combined potential savings of £2,042 per month, or £24,504 annually.

The largest opportunity is reviewing the low-utilisation RDS read replica, with potential savings of £1,240 per month.

The second is downsizing the RDS primary, with potential savings of £490 per month.

The third is downsizing the EC2 application server, with potential savings of £312 per month.

These changes should be validated individually before implementation to avoid creating new availability or performance risks.

Finally, production readiness.

Monitoring has significantly improved, and Kubernetes and Terraform recovery runbooks are present.

However, I would not provide unconditional production sign-off today.

The supplied security register still records three CRITICAL findings as open: public S3 access, a hardcoded database credential in the repository, and excessive IAM wildcard permissions.

Those issues need to be remediated, technically verified and formally closed before final production approval.

In summary, we have confirmed the immediate technical cause of INC-2024-047, documented the recovery timeline, identified preventive actions, identified more than twenty-four thousand pounds in potential annual cloud savings, and assessed the platform's production readiness.

The remaining priority is closing and verifying the critical security findings before final production sign-off.

Thank you.
