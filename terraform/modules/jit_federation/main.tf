# Dynamically fetch the current AWS Account ID
data "aws_caller_identity" "current" {}

# Trust policy requiring MFA and limiting session usage via federation
data "aws_iam_policy_document" "jit_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/OnPremisesADFS"]
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
