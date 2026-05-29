# NimbusCloud Platform — DynamoDB Configuration

resource "aws_dynamodb_table" "sessions" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"
  range_key      = "user_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIdIndex"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name      = "nimbuscloud-sessions"
    GDPRScope = "true"
    DataClass = "confidential"
  }
}

# SQS Queue for notifications
resource "aws_sqs_queue" "notifications" {
  name                      = var.notification_queue_name
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "nimbuscloud-notifications-queue"
  }
}

resource "aws_sqs_queue" "notifications_dlq" {
  name                      = "${var.notification_queue_name}-dlq"
  message_retention_seconds = 604800

  tags = {
    Name = "nimbuscloud-notifications-dlq"
  }
}

# Lambda — notification dispatcher
resource "aws_lambda_function" "notification_dispatcher" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  filename = "${path.module}/lambda/notification_dispatcher.zip"

  environment {
    variables = {
      SQS_QUEUE_URL  = aws_sqs_queue.notifications.url
      SES_FROM_EMAIL = "noreply@nimbuscloud.io"
      ENVIRONMENT    = var.environment
    }
  }

  tags = {
    Name = "nimbuscloud-notification-dispatcher"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.notifications.arn
  function_name    = aws_lambda_function.notification_dispatcher.arn
  batch_size       = 10
  enabled          = true
}

