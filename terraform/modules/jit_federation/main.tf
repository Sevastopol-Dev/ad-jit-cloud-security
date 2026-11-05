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

# Trust policy requiring MFA and limiting session usage via federation
data "aws_iam_policy_document" "jit_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::ACCOUNT-ID:saml-provider/OnPremisesADFS"]
    }

    # CRITICAL SECURITY CONTROL: Enforce MFA assertion presence
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    # Restrict assumption to corporate network source IP range if desired
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["10.0.0.0/8", "192.168.1.0/24"]
    }
  }
}

resource "aws_iam_role" "jit_federated_role" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.jit_trust.json
  max_session_duration = var.max_session_duration

  tags = {
    Environment = "ZeroStandingPrivileges"
    ManagedBy   = "Terraform"
  }
}

# Output the role ARN for downstream pipeline integration
output "jit_role_arn" {
  value       = aws_iam_role.jit_federated_role.arn
  description = "ARN of the ephemeral JIT federated role"
}