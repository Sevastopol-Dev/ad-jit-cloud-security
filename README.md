# AD-JIT-Cloud-Security 🛡️

Legacy hybrid enterprise environments rely on static, standing administrative privileges across Active Directory and cloud control planes, creating an unmonitored attack vector for privilege escalation. Cloud and security engineers face catastrophic blast radius expansion when these long-lived credentials are leaked or abused, as traditional user controls fail to govern automated scripts and manual admin sessions.

```
       [ Operator Workstation / Corporate Network ]
                         │
                         │ 1. Requests JIT Elevation (--duration 15m)
                         ▼
          [ JitElevation.py Orchestrator ]
                         │
                         ├─► Mutates AD Group Membership (Ephemeral Add)
                         ├─► Enforces Strict TTL Countdown & Heartbeats
                         │
                         │ 2. Terraform Federated Trust Asserts MFA & IP Range
                         ▼
          [ AWS IAM / Local Active Directory ]
                         │
                         └─► Guaranteed Cleanup via try...finally Revocation
```

---

## Architecture Decisions

- **Privilege Model: Zero Standing Privileges (ZSP) via Ephemeral JIT (Selected) vs. Permanent Admin Accounts (Rejected)**
  - *Why:* Standing admin accounts provide a permanent target for credential-stuffing and pass-the-hash attacks. JIT elevation limits exposure windows to active change-management windows only (capped at 60 minutes).

- **Execution Safety: Guaranteed `try...finally` Revocation (Selected) vs. Manual Script Exit (Rejected)**
  - *Why:* Custom elevation scripts frequently leave orphaned permissions behind when they crash or are interrupted by an operator. Wrapping the lifecycle in a guaranteed teardown block ensures baseline privileges are always restored.

- **Infrastructure Provisioning: Modular Terraform with CI/CD Linting (Selected) vs. Manual Portal Configuration (Rejected)**
  - *Why:* Manual identity provisioning leads to configuration drift and hidden permission creep. Declarative IaC combined with Checkov and TFlint scans enforces security posture pre-merge.

---

## Production Engineering & Governance

### Repository Directory Structure (`.`)

```text
.
├── .checkov.yaml
├── .github
│   └── workflows
│       └── security-lint.yml
├── Makefile
├── README.md
├── scripts
│   └── JitElevation.py
└── terraform
    ├── main.tf
    ├── modules
    │   └── jit_federation
    │       ├── main.tf
    │       ├── s3_audit.tf
    │       ├── variables.tf
    │       └── versions.tf
    └── variables.tf
```

### Monitoring & Telemetry Strategy

- **Audit Logs:** Monitor Active Directory event logs (Event ID 4728/4732 for security-enabled global group membership changes) alongside AWS CloudTrail logs for `AssumeRole` and `TagSession` API calls. Immutable JIT session logs are written directly to S3 Object Lock storage in COMPLIANCE mode.
- **Alerting Guardrails:** SIEM detection rules configured for any session duration exceeding 30 minutes or execution outside approved corporate IP subnets (`10.0.0.0/8`, `192.168.1.0/24`).

### Monthly Cost Estimate

| Resource | Service Tier | Estimated Cost (USD) |
| :--- | :--- | :--- |
| **AWS IAM / STS Federation** | Standard Control Plane | $0.00 / Included |
| **Active Directory Domain Services** | Self-Hosted Hypervisor Lab | $0.00 |
| **GitHub Actions CI/CD** | Public Runner Tier | $0.00 |
| **Total Estimated Run Cost** | | **$0.00 / Free Tier Lab** |

---

## What Broke and What I Changed

> **Incident:** During initial multi-platform testing of `JitElevation.py`, running the script on a local developer Linux workstation threw an unhandled `FileNotFoundError` because the native Windows `net` utility was missing.

- **Root Cause Analysis:** The script directly invoked Windows command-line binaries without checking the underlying host operating system runtime environment.
- **Engineering Fix:** Implemented a platform detection check (`platform.system()`) that gracefully branches execution—running native Windows `net` commands in production domains while providing safe, logged simulation mocks for local Linux development testing.

---

## Deployment & Teardown

### Prerequisites

- Terraform v1.5+ installed
- Python 3.11+ with Ruff and Bandit
- AWS CLI configured with appropriate administrative privileges (for IaC deployment)

### 1. Deployment Steps

```bash
# Clone the repository
git clone https://github.com/Sevastapol/ad-jit-cloud-security.git
cd ad-jit-cloud-security/terraform

# Initialize Terraform modules
terraform init

# Validate configuration syntax
terraform validate

# Plan and apply the JIT trust baseline
terraform plan -out=tfplan
terraform apply tfplan
```

### 2. Teardown Steps

```bash
# Destroy managed infrastructure cleanly
terraform destroy -auto-approve
```