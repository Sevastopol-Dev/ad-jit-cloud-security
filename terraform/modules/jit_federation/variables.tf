variable "aws_region" {
  type        = string
  description = "Target AWS deployment region"
  default     = "us-east-1"
}

variable "role_name" {
  type        = string
  description = "Name of the ephemeral JIT IAM role"
  default     = "JIT-Ephemeral-CloudAdmin"
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session TTL in seconds (default: 1800s / 30 mins)"
  default     = 1800
}

variable "audit_bucket_name" {
  type        = string
  description = "Globally unique name for the immutable S3 audit log bucket"
  default     = "ad-jit-immutable-audit-logs-prod"
}

variable "audit_log_retention_days" {
  type        = number
  description = "Number of days compliance retention is enforced on audit logs"
  default     = 365
}

