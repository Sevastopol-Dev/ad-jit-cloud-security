variable "aws_region" {
  type        = string
  description = "Target AWS deployment region"
  default     = "us-east-1"
}

variable "jit_role_name" {
  type        = string
  description = "Name for the ephemeral JIT IAM role"
  default     = "JIT-Ephemeral-CloudAdmin"
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session TTL in seconds"
  default     = 1800
}
