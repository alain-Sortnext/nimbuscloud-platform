# NimbusCloud Platform — IAM Configuration
# ⚠️ CRITICAL SECURITY FINDING: platform_role has wildcard Action and Resource
#    This was flagged by Fatima Al-Rashid (Security) on 2026-04-30
#    Ref: SEC-FINDING-2026-003
#    Must be replaced with least-privilege policy before go-live

# ─────────────────────────────────────────────
# IAM Role — Platform Services
# ─────────────────────────────────────────────

resource "aws_iam_role" "platform_role" {
  name = "nimbuscloud-platform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "nimbuscloud-platform-role"
  }
}

# ⚠️ CRITICAL: Overprivileged inline policy
# This grants ALL actions on ALL resources — violates least privilege
# Must be replaced with scoped policy (see SEC-FINDING-2026-003)
resource "aws_iam_role_policy" "platform_policy" {
  name = "nimbuscloud-platform-policy"
  role = aws_iam_role.platform_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::nimbuscloud-platform-assets-${var.bucket_suffix}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/nimbuscloud-sessions"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "arn:aws:sqs:${var.aws_region}:*:nimbuscloud-notifications-queue"
      },
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:nimbuscloud-notification-dispatcher"
      },
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:nimbuscloud/db-password-*"
      }
    ]
  })
}
# ─────────────────────────────────────────────
# IAM Role — Lambda Execution
# ─────────────────────────────────────────────

resource "aws_iam_role" "lambda_execution_role" {
  name = "nimbuscloud-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "nimbuscloud-lambda-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:eu-west-2:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

