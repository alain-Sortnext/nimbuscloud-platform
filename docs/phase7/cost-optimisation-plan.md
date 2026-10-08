# NimbusCloud Cost Optimisation Plan

## Objective

Identify the three largest potential monthly savings in aws_cost_report_may2026.csv.

## Top Three Opportunities

| Service | Resource | Current Monthly Cost | Utilisation | Recommendation | Potential Monthly Saving |
|---|---|---:|---:|---|---:|
| RDS | nimbuscloud-db-replica | £1240 | 15% | Consider removing read replica - usage low | £1240 |
| RDS | nimbuscloud-db-primary | £1240 | 18% | Downsize from db.r5.large to db.t3.medium - avg connections 12 | £490 |
| EC2 | nimbuscloud-app-server-01 | £847 | 23% | Downsize from m5.xlarge to m5.large - avg CPU 23% | £312 |

## Financial Impact

Total potential monthly saving: **£2,042.00**

Total potential annual saving: **£24,504.00**

## Priority Plan

### 1. RDS read replica

Review whether nimbuscloud-db-replica is required. Its utilisation is 15%, and the source cost report recommends considering removal because usage is low.

Potential saving: £1,240 per month.

Removal must only occur after confirming that production availability, read scaling and disaster-recovery requirements do not depend on the replica.

### 2. RDS primary

Downsize nimbuscloud-db-primary from db.r5.large to db.t3.medium as recommended by the source report.

Utilisation: 18%.

Potential saving: £490 per month.

Validate workload capacity and performance before production resizing.

### 3. EC2 application server

Downsize nimbuscloud-app-server-01 from m5.xlarge to m5.large.

Average utilisation: 23%.

Potential saving: £312 per month.

Validate CPU, memory and peak workload requirements before resizing.

## Recommendation

Implement the changes through normal change management and verify performance after each optimisation rather than applying all three changes simultaneously.
