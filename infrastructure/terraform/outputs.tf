# NimbusCloud Platform — Terraform Outputs
# ⚠️ BUG: output "alb_dns_name" references aws_lb.nimbuscloud_alb
#         but the resource is named aws_lb.main in main.tf
#         This will cause: Error: Reference to undeclared resource
#         Fix: change aws_lb.nimbuscloud_alb.dns_name → aws_lb.main.dns_name

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  # BUG: wrong resource name — was renamed from nimbuscloud_alb to main
  value       = aws_lb.nimbuscloud_alb.dns_name
}

output "s3_bucket_name" {
  description = "S3 assets bucket name"
  value       = aws_s3_bucket.assets.id
}

output "dynamodb_table_name" {
  description = "DynamoDB sessions table name"
  value       = aws_dynamodb_table.sessions.name
}

output "platform_role_arn" {
  description = "IAM role ARN for platform services"
  value       = aws_iam_role.platform_role.arn
}

output "notifications_queue_url" {
  description = "SQS notifications queue URL"
  value       = aws_sqs_queue.notifications.url
}

