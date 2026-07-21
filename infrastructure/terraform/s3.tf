# NimbusCloud Platform — S3 Configuration
# ✅ SEC-2026-001 REMEDIATED

# ============================================
# ASSETS BUCKET - Client Data Storage
# ============================================
resource "aws_s3_bucket" "assets" {
  bucket = "nimbuscloud-platform-assets-${var.bucket_suffix}"

  tags = {
    Name        = "nimbuscloud-platform-assets"
    DataClass   = "confidential"
    GDPRScope   = "true"
    Security    = "private"
  }
}

# ✅ Block all public access (this is the primary security control)
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning — enabled
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption — enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================
# TERRAFORM STATE BUCKET - Infrastructure State
# ============================================
resource "aws_s3_bucket" "terraform_state" {
  bucket = "nimbuscloud-terraform-state-${var.bucket_suffix}"

  tags = {
    Name      = "nimbuscloud-terraform-state"
    Protected = "true"
    Security  = "private"
  }
}

# Block public access for state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption for terraform state
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}