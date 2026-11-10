# ==========================================
# 1. PRIMARY IMMUTABLE AUDIT LOG BUCKET
# ==========================================

# checkov:skip=CKV_AWS_144:Single-region portfolio architecture
# checkov:skip=CKV2_AWS_62:Event notifications not required for audit logs bucket
resource "aws_s3_bucket" "audit_logs" {
  bucket              = var.audit_bucket_name
  object_lock_enabled = true
  force_destroy       = false # Safety: prevent accidental deletion of audit records

  tags = {
    Environment = "ZeroStandingPrivileges"
    Purpose     = "JIT Audit Trail Compliance Storage"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "audit_versioning" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_crypto" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_block_public" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object_lock_configuration" "audit_lock_policy" {
  bucket     = aws_s3_bucket.audit_logs.id
  depends_on = [aws_s3_bucket_versioning.audit_versioning]

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.audit_log_retention_days
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs_lifecycle" {
  bucket     = aws_s3_bucket.audit_logs.id
  depends_on = [aws_s3_bucket_versioning.audit_versioning]

  rule {
    id     = "audit-logs-glacier-transition"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "deny_deletion" {
  bucket = aws_s3_bucket.audit_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyObjectDeletion"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = "${aws_s3_bucket.audit_logs.arn}/*"
      }
    ]
  })
}


# ==========================================
# 2. SERVER ACCESS LOGGING DESTINATION
# ==========================================

# checkov:skip=CKV_AWS_144:Single-region portfolio architecture
# checkov:skip=CKV2_AWS_62:Event notifications not required for log bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${var.audit_bucket_name}-access-logs"
  force_destroy = true

  tags = {
    Environment = "ZeroStandingPrivileges"
    Purpose     = "Access Logs Destination"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "log-bucket-retention-and-cleanup"
    status = "Enabled"

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "audit_logs_logging" {
  bucket = aws_s3_bucket.audit_logs.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
