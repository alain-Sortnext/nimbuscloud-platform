
# Environment
variable "environment" {
  description = "Deployment environment (production, staging, development)"
  type        = string
  default     = "development"
}

# Database password (stored in Secrets Manager)
variable "db_password_initial" {
  description = "Initial database password (will be stored in Secrets Manager)"
  type        = string
  sensitive   = true
  default     = "NimbusCloudSecurePassword2026!"
}
