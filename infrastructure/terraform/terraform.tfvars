# NimbusCloud Platform — Terraform Variable Values
# ⚠️ This file is intentionally incomplete — see variables.tf for missing variables
# Do NOT commit secrets to this file

aws_region              = "eu-west-2"
dynamodb_table_name     = "nimbuscloud-sessions"
notification_queue_name = "nimbuscloud-notifications-queue"
lambda_function_name    = "nimbuscloud-notification-dispatcher"
app_version             = "2.4.1"

# MISSING: environment — add below
# environment = "production"

# MISSING: bucket_suffix — add below (use your AWS account ID for uniqueness)
# bucket_suffix = "prod-123456789012"

