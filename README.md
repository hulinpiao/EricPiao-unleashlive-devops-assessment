# AWS DevOps Assessment

> Multi-region AWS infrastructure deployment using Terraform with CI/CD automation.

---

## Project Overview

This project demonstrates a DevOps engineer's ability to design, implement, and deploy a multi-region AWS infrastructure using Infrastructure as Code (IaC) principles.

**Architecture:** Deploy identical infrastructure in `us-east-1` and `eu-west-1` regions with shared Cognito authentication.

---

## Directory Structure

```
aws-assessment/
├── .github/           # CI/CD automation
│   └── workflows/     # GitHub Actions pipelines
│
├── terraform/         # Infrastructure as Code
│   ├── modules/       # Reusable Terraform modules
│   ├── us-east-1/     # US East region deployment
│   └── eu-west-1/     # EU West region deployment
│
├── tests/             # Integration tests
│   └── integration_test.py
│
└── docs/              # Project documentation
    ├── PRD.md
    ├── Solution-Architecture.md
    └── ...
```

---

## Directory Descriptions

| Directory | Purpose |
|-----------|---------|
| **`.github/`** | GitHub Actions CI/CD pipelines for automated validation, security scanning, and deployment |
| **`terraform/`** | All Terraform IaC code - modules, regional deployments, and configuration |
| **`tests/`** | Integration test scripts to validate deployed API endpoints |
| **`docs/`** | Project documentation including PRD, architecture, and task plans |

---

## Quick Start

### Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.7.0
- Python 3.11 (for tests)

### Deploy

```bash
# Deploy us-east-1 (includes Cognito)
cd terraform/us-east-1
terraform init
terraform apply

# Deploy eu-west-1 (references us-east-1 Cognito)
cd ../eu-west-1
terraform init
terraform apply
```

### Test

```bash
cd tests
pip install -r requirements.txt
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

### Cleanup

```bash
# Destroy eu-west-1 first
cd terraform/eu-west-1 && terraform destroy

# Then destroy us-east-1
cd ../us-east-1 && terraform destroy
```

---

## CI/CD Pipeline

This project includes automated CI/CD via GitHub Actions:

- **Lint/Validate:** Code format and syntax checks
- **Security Scan:** tfsec vulnerability scanning
- **Plan:** Infrastructure change preview
- **Test:** Integration test execution

See [`.github/workflows/README.md`](.github/workflows/README.md) for details.

---

## Documentation

| Document | Description |
|----------|-------------|
| [`docs/PRD.md`](docs/PRD.md) | Product Requirements Document |
| [`docs/Solution-Architecture.md`](docs/Solution-Architecture.md) | Technical architecture design |
| [`docs/Engineering-Delivery.md`](docs/Engineering-Delivery.md) | Development workflow and CI/CD details |

---

## AWS Resources

| Service | Purpose |
|---------|---------|
| **Cognito** | User authentication (us-east-1 only, shared across regions) |
| **API Gateway** | HTTP API with /greet and /dispatch endpoints |
| **Lambda** | Serverless function handlers |
| **DynamoDB** | GreetingLogs table |
| **ECS Fargate** | Container execution for /dispatch |
| **SNS** | Verification message delivery |

---

*Version: 1.0*
*Last Updated: 2026-03-04*
