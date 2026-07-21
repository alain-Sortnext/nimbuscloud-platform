# NimbusCloud Platform — AWS Secrets Manager Configuration
# SEC-2026-002: DB_PASSWORD moved to Secrets Manager

# Secrets Manager Secret for Database Password
resource "aws_secretsmanager_secret" "db_password" {
  name = "nimbuscloud/db-password"
  description = "Database password for NimbusCloud auth-service and other services"

  # Rotation rules - comment out if not supported in your region
  # rotation_rules {
  #   automatically_after_days = 30
  # }

  tags = {
    Name        = "nimbuscloud-db-password"
    Environment = var.environment
    ManagedBy   = "Terraform"
    DataClass   = "confidential"
  }
}

# Secret version with initial password
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    DB_PASSWORD = var.db_password_initial
  })
}
