# CI/CD Pipeline Documentation

> GitHub Actions workflow for automated validation and deployment of Terraform code.

---

## 1. Pipeline Flow Diagram

### Auto-trigger Flow (push / PR to main)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Code pushed to main branch                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 1: Lint & Validate                                       │
│  Check code format and syntax                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 2: Security Scan                                         │
│  tfsec security vulnerability scan                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 3: Plan                                                  │
│  Preview infrastructure changes (us-east-1 and eu-west-1 in parallel) │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 5: Integration Test                                      │
│  Run integration tests (verify API endpoints)                   │
└─────────────────────────────────────────────────────────────────┘
```

### Manual Trigger Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Manual trigger (workflow_dispatch)            │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ Default       │   │ run_tests_only│   │ apply_changes │
│ option        │   │ = true        │   │ = true        │
│               │   │               │   │               │
│ Full flow     │   │ Run tests     │   │ Execute       │
│ Lint→Scan→Plan│   │ directly      │   │ deployment    │
└───────────────┘   └───────────────┘   └───────────────┘
```

---

## 2. Stage Descriptions

### Stage 1: Lint & Validate

**Purpose:** Ensure consistent code format and correct syntax

| Check Item | Tool | Description |
|------------|------|-------------|
| Format Check | `terraform fmt -check` | Check if code indentation, line breaks, brackets conform to standards |
| Syntax Validation | `terraform validate` | Check Terraform syntax correctness and valid resource references |

**Why it's needed:**
- Unify code style for team collaboration
- Catch syntax errors early to prevent later stage failures
- Fast execution without AWS credentials

---

### Stage 2: Security Scan (tfsec)

**Purpose:** Scan Terraform code for security vulnerabilities and configuration issues

**tfsec Rule Categories:**

| Category | Check Content | Example |
|----------|---------------|---------|
| **AWS Security** | S3 bucket public access, overly permissive security groups | Public S3 bucket, security group allowing 0.0.0.0/0 |
| **Encryption** | Data encryption at rest | RDS without encryption, S3 without server-side encryption |
| **Network** | Secure network configuration | Lambda outside VPC, exposed database ports |
| **IAM** | Least privilege principle | Using `*:*` wildcard permissions |
| **Logging** | Audit logging enabled | CloudTrail not enabled, S3 access logging not enabled |

**Why it's needed:**
- Detect security risks before deployment
- Follow security best practices
- Prevent security vulnerabilities in production

---

### Stage 3: Plan

**Purpose:** Preview upcoming infrastructure changes

**Plan tells you:**
- `+` Resources to be created
- `-` Resources to be deleted
- `~` Resources to be modified

**Why it's needed:**
- See changes before actual deployment
- Prevent accidental deletion of important resources
- Two regions (us-east-1, eu-west-1) execute in parallel for efficiency

**Note:** This stage requires AWS credentials to execute

---

### Stage 4: Apply

**Purpose:** Execute infrastructure changes (manual trigger)

**Trigger Method:**
1. Run the default flow once to generate Plan artifact
2. Then manually trigger with `apply_changes = true`

**Optional Parameters:**
- `apply_region`: Select deployment region (all / us-east-1 / eu-west-1)

**Why manual trigger is needed:**
- Prevent accidental deployment to production
- Give team opportunity to review Plan results
- Follow DevOps best practices

---

### Stage 5: Integration Test

**Purpose:** Verify deployed API is working correctly

**Test Content:**
1. Cognito authentication (get JWT token)
2. us-east-1 /greet endpoint
3. us-east-1 /dispatch endpoint
4. eu-west-1 /greet endpoint
5. eu-west-1 /dispatch endpoint
6. SNS message sending
7. Response latency comparison

---

## 3. Test Execution Special Architecture

> **Important:** Integration Test supports multiple trigger methods

```
┌─────────────────────────────────────────────────────────────────┐
│                  Integration Test Trigger Methods                │
└─────────────────────────────────────────────────────────────────┘

Method 1: Sequential Trigger (Automatic)
┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐
│  Lint  │ ──► │  Scan  │ ──► │  Plan  │ ──► │  Test  │
└────────┘     └────────┘     └────────┘     └────────┘
                                 after success


Method 2: Manual Trigger (Anytime)
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│    Manual trigger: run_tests_only = true                       │
│                    │                                           │
│                    ▼                                           │
│              ┌────────┐                                        │
│              │  Test  │  ← Skip all prerequisite steps,        │
│              └────────┘    execute tests directly              │
│                                                                │
└────────────────────────────────────────────────────────────────┘


Method 3: Post-deployment Trigger
┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐
│  Plan  │ ──► │ Apply  │ ──► │  Test  │
└────────┘     └────────┘     └────────┘
   (previous)   (manual)       (auto after deployment success)
```

**Use Cases:**

| Scenario | Recommended Method |
|----------|-------------------|
| Daily development verification | Method 1 (Automatic) |
| Quick regression testing | Method 2 (Manual) |
| Post-production deployment verification | Method 3 (Post-deployment) |

---

## 4. Manual Trigger Parameters

When clicking "Run workflow" on GitHub Actions page:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `run_tests_only` | Run tests only, skip other steps | `false` |
| `apply_changes` | Execute terraform apply | `false` |
| `apply_region` | Deployment region | `all` |
| `environment` | Test environment | `development` |

---

## 5. Required Secrets Configuration

| Secret | Description | Required For |
|--------|-------------|--------------|
| `AWS_ACCESS_KEY_ID` | AWS access key | Plan/Apply/Test |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | Plan/Apply/Test |
| `COGNITO_USER_POOL_ID` | Cognito Pool ID | Test |
| `COGNITO_CLIENT_ID` | Cognito Client ID | Test |
| `API_URL_US_EAST_1` | us-east-1 API URL | Test |
| `API_URL_EU_WEST_1` | eu-west-1 API URL | Test |
| `TEST_EMAIL` | Test user email | Test |
| `TEST_PASSWORD` | Test user password | Test |

**Configuration Path:** GitHub Repository → Settings → Secrets and variables → Actions

---

## 6. Local Execution

To run the same checks locally:

```bash
# Format check
terraform fmt -check -recursive

# Syntax validation
cd terraform/us-east-1 && terraform init -backend=false && terraform validate
cd terraform/eu-west-1 && terraform init -backend=false && terraform validate

# Security scan (requires tfsec installation)
tfsec .

# Plan
cd terraform/us-east-1 && terraform init && terraform plan
cd terraform/eu-west-1 && terraform init && terraform plan

# Test
cd tests && pip install -r requirements.txt
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

---

*Document Version: 1.0*
*Last Updated: 2026-03-04*
