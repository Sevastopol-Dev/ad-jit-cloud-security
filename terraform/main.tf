terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}

# Instantiate the JIT Federation Module
module "jit_federation" {
  source               = "./modules/jit_federation"
  role_name            = var.jit_role_name
  max_session_duration = var.max_session_duration
}

# Expose the module's output at the root level
output "role_arn" {
  value       = module.jit_federation.jit_role_arn
  description = "The ARN of the JIT federated IAM role"
}
