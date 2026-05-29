# NimbusCloud Platform — Terraform Variables
# ⚠️ BUG: variables `environment` and `bucket_suffix` are declared here
#         but NOT passed in terraform.tfvars — terraform apply will prompt
#         interactively and may fail in CI. Add them to terraform.tfvars.

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Deployment environment (production, staging, development)"
  type        = string
  # BUG: no default — must be supplied. Missing from terraform.tfvars.
  # Candidate must add: environment = "production" to terraform.tfvars
}

variable "bucket_suffix" {
  description = "Suffix appended to S3 bucket name to ensure global uniqueness"
  type        = string
  # BUG: no default — must be supplied. Missing from terraform.tfvars.
  # Candidate must add: bucket_suffix = "prod-<account-id>" to terraform.tfvars
}

variable "dynamodb_table_name" {
  description = "Name of the primary DynamoDB sessions table"
  type        = string
  default     = "nimbuscloud-sessions"
}

variable "notification_queue_name" {
  description = "SQS queue name for notification service"
  type        = string
  default     = "nimbuscloud-notifications-queue"
}

variable "lambda_function_name" {
  description = "Lambda function name for notification dispatcher"
  type        = string
  default     = "nimbuscloud-notification-dispatcher"
}

variable "app_version" {
  description = "Application version tag for container images"
  type        = string
  default     = "2.4.1"
}

