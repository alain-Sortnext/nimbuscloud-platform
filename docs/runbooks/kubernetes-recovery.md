# Runbook: Kubernetes Recovery
## NimbusCloud Platform — Platform Engineering Team
**Last updated:** 2026-04-28 (Jordan Reeves)

---

## Quick Reference — Common Commands

```bash
# Check pod status
kubectl get pods -n default

# Check pod details (why is it failing?)
kubectl describe pod <pod-name> -n default

# Check pod logs
kubectl logs <pod-name> -n default
kubectl logs <pod-name> -n default --previous   # crashed container logs

# Restart a deployment
kubectl rollout restart deployment/<deployment-name> -n default

# Apply manifest changes
kubectl apply -f infrastructure/kubernetes/

# Check events (recent cluster events — useful for debugging)
kubectl get events -n default --sort-by='.lastTimestamp'
```

---

## Diagnosing CrashLoopBackOff

CrashLoopBackOff means the container starts, crashes, and Kubernetes keeps restarting it.

**Step 1: Identify which pods are crashing**
```bash
kubectl get pods -n default
```
Look for `CrashLoopBackOff` or `Error` in the STATUS column.

**Step 2: Check the error**
```bash
kubectl describe pod <pod-name> -n default
```
Look at:
- `State:` — shows current state and exit code
- `Last State:` — shows previous crash reason
- `Events:` at bottom — shows what Kubernetes tried to do

**Step 3: Check application logs**
```bash
kubectl logs <pod-name> -n default --previous
```
The `--previous` flag shows logs from the most recent crashed container.

**Common causes:**
| Symptom | Likely cause | Fix |
|---|---|---|
| `Error from server: configmaps "X" not found` | ConfigMap missing | `kubectl apply -f configmap.yaml` |
| `secret "X" not found` | Secret missing | Create the secret: `kubectl apply -f secret.yaml` |
| `key "X" not found in ConfigMap "Y"` | Wrong key name in deployment | Update configmap OR deployment to match |
| OOMKilled | Memory limit hit | Increase memory limit in deployment.yaml |
| Readiness probe failing | Wrong probe path | Fix health check path in deployment.yaml |

---

## Diagnosing Readiness Probe Failures

```bash
kubectl describe pod <pod-name> | grep -A 10 "Readiness"
```

If you see `Readiness probe failed: HTTP probe failed with statuscode: 404`:
- The pod IS running but Kubernetes won't send it traffic
- Check that the health check path in deployment.yaml matches what the service exposes
- NimbusCloud services expose `/healthz` — NOT `/health`

---

## Emergency Restart Procedure

If a service is down and you need immediate recovery:

```bash
# Restart specific service
kubectl rollout restart deployment/booking-api -n default
kubectl rollout restart deployment/payment-api -n default
kubectl rollout restart deployment/auth-service -n default
kubectl rollout restart deployment/notification-service -n default

# Watch rollout status
kubectl rollout status deployment/booking-api -n default
```

> ⚠️ NOTE: Rollout restart is a recovery action — it does not fix underlying issues.
> Always identify and fix the root cause after emergency recovery.

---

## Using Lens for Visual Diagnostics

1. Open Lens Desktop
2. Connect to your Minikube cluster
3. Navigate to Workloads → Pods
4. Click any pod to see: logs, events, resource usage, describe output
5. Use Lens → Shell to exec into a running pod

---

## Known Issues (current)

See README.md for full list. Active Kubernetes issues:
- booking-api: CrashLoopBackOff (ConfigMap key mismatch)
- payment-api: Missing Secret
- auth-service: Readiness probe path wrong
- notification-service ingress: Wrong port in ingress.yaml

