# NimbusCloud Platform — S3 Configuration
# ⚠️ CRITICAL SECURITY FINDING: assets bucket has public-read ACL
#    Flagged by Fatima Al-Rashid — ref: SEC-FINDING-2026-001
#    UK GDPR Article 32 breach risk — must be remediated immediately

resource "aws_s3_bucket" "assets" {
  bucket = "nimbuscloud-platform-assets-${var.bucket_suffix}"

  tags = {
    Name        = "nimbuscloud-platform-assets"
    DataClass   = "confidential"
    GDPRScope   = "true"
  }
}

# ⚠️ BUG: public-read ACL on a bucket containing client data
# This must be removed and replaced with private + bucket policy
resource "aws_s3_bucket_acl" "assets_acl" {
  bucket = aws_s3_bucket.assets.id
  acl    = "public-read"    # WRONG — must be "private"
}

# Versioning — enabled (good)
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption — enabled (good)
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ⚠️ PUBLIC ACCESS BLOCK IS DISABLED — must be enabled
# resource "aws_s3_bucket_public_access_block" "assets" {
#   bucket                  = aws_s3_bucket.assets.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# Terraform state bucket (separate — do not modify)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "nimbuscloud-terraform-state-${var.bucket_suffix}"

  tags = {
    Name      = "nimbuscloud-terraform-state"
    Protected = "true"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

