# AD-Cloud-Security-Baseline 🛡️

An enterprise-grade, terminal-first hybrid identity federation and Just-In-Time (JIT) privilege elevation framework designed to eliminate standing administrative privileges across local Active Directory and multi-cloud environments.

## Core Pillars
* **Zero Standing Privileges (ZSP):** Hard-caps administrative access through ephemeral group memberships and strict TTL countdowns (max 60-minute windows).
* **Guaranteed Rollback:** Leverages robust `try...finally` execution guards to ensure automatic privilege revocation even upon script interruption or failure.
* **Cryptographic Cloud Federation:** Terraform-provisioned IAM trust policies enforcing strict multi-factor authentication assertions (`aws:MultiFactorAuthPresent`) and session boundaries.
* **Automated Security Gates:** Integrated CI/CD linting pipelines using Ruff, TFlint, and Checkov to catch configuration drift and security misconfigurations pre-merge.