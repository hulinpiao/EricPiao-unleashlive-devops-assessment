# Engineering Delivery / Dev Workflow

## Vibe Coding Phase - Team Agents Collaboration Guide

---

## 1. Repo Structure

### Decision: Monorepo

```
aws-assessment/
├── terraform/
│   ├── modules/              # Shared modules
│   │   ├── api-gateway/
│   │   ├── lambda-greet/
│   │   ├── lambda-dispatch/
│   │   ├── dynamodb/
│   │   ├── ecs-fargate/
│   │   └── cognito/
│   ├── us-east-1/           # us-east-1 region deployment
│   │   ├── main.tf          # Main configuration
│   │   ├── backend.tf
│   │   ├── providers.tf
│   │   ├── cognito.tf       # Cognito module invocation
│   │   ├── greet.tf         # /greet related modules
│   │   ├── dispatch.tf      # /dispatch related modules
│   │   ├── api-gateway.tf   # API Gateway module
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   └── eu-west-1/           # eu-west-1 region deployment
│       ├── main.tf          # Main configuration
│       ├── backend.tf
│       ├── providers.tf
│       ├── greet.tf         # /greet related modules
│       ├── dispatch.tf      # /dispatch related modules
│       ├── api-gateway.tf   # API Gateway module
│       ├── terraform.tfvars
│       └── outputs.tf
├── tests/
│   ├── requirements.txt
│   └── integration_test.py
├── docs/
│   ├── PRD.md
│   ├── Solution-Architecture.md
│   ├── Engineering-Delivery.md
│   ├── Multi-Agent-Rules.md
│   └── Task-Plan.md
├── .github/
│   └── workflows/
│       └── validate.yml     # CI/CD pipeline
├── README.md
└── .gitignore
```

**Rationale:** A single repository facilitates management, code sharing, and is suitable for assessment projects.

---

## 2. Branching Strategy

### Decision: Trunk-Based Development

```
main (direct commits)
```

**Workflow:**
1. Develop directly on the `main` branch
2. Run local checks before committing
3. Automatic CI/CD verification after commit

**Rationale:** The assessment project is simple and straightforward, requiring no complex branch management.

---

## 3. Environment Strategy

### Decision: Single Environment

**Actual Situation:** Only one deployment environment, distinguished between development/validation phases by switching SNS Topic ARN

| Phase | SNS Topic ARN | terraform.tfvars |
|-------|---------------|-------------------|
| **Development/Validation** | `arn:aws:sns:us-east-1:160676960050:Candidate-Verification-Topic` | `sns_topic_arn = "arn:..."` |

**Switching Method:** Manually modify the `sns_topic_arn` variable in `terraform.tfvars`

---

## 4. Local Dev Workflow

### Decision: Direct Deployment + Plan Troubleshooting

```
1. Edit Terraform code
       │
       ▼
2. terraform fmt          # Format
       │
       ▼
3. terraform init         # Initialize
       │
       ▼
4. terraform plan         # Preview changes
       │
       ▼
5. terraform apply        # Deploy to AWS
       │
       ▼
6. Run test script for validation
       │
       ▼
7. Adjust based on results
       │
       └──► Failure → terraform plan troubleshooting → redeploy
```

**Deployment Failure Troubleshooting:** Use `terraform plan` to view error messages

---

## 5. AI Agent Roles

### Decision: 4 Roles

| Agent | Responsibilities | Concurrent Role |
|-------|------------------|-----------------|
| **Team Lead / Planner** | Task allocation, progress tracking, coordination | - |
| **IaC Agent / Reviewer** | Write Terraform code, code review, self-check | Concurrent Reviewer |
| **Test Agent** | Write test scripts, validate functionality | - |
| **Doc Agent** | Write README, documentation | - |

### Agent Collaboration Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      Vibe Coding Workflow                        │
└─────────────────────────────────────────────────────────────────┘

  Team Lead assigns tasks
        │
        ▼
  IaC Agent writes code
        │
        ├─► terraform fmt + validate + tfsec (self-check)
        │
        ▼
  Test Agent validates functionality
        │
        ├─► Run test scripts
        │
        ▼
  Validation passed?
  ├─ Yes → Doc Agent writes documentation
  │         │
  │         ▼
  │    Task completed
  │
  └─ No → IaC Agent fixes issues
             │
             └──► Re-validate
```

---

## 6. CI/CD Stages

### Decision: 4 Stages per PRD Requirements

> **PRD Requirement:** A DevOps engineer doesn't deploy from their laptop. Include a CI/CD pipeline configuration file that defines automated steps.

---

### 6.1 Pipeline Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GitHub Actions Workflow                               │
│                     .github/workflows/validate.yml                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Trigger: push / pull_request to main                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│  Stage 1      │         │  Stage 2      │         │               │
│  Lint/Validate│         │  Security Scan│         │               │
│               │         │               │         │               │
│ terraform fmt │         │    tfsec      │         │               │
│ terraform     │         │               │         │               │
│   validate    │         │               │         │               │
│ (both regions)│         │               │         │               │
└───────┬───────┘         └───────┬───────┘         │               │
        │                         │                 │               │
        └────────────┬────────────┘                 │               │
                     │                              │               │
                     ▼                              │               │
        ┌────────────────────────┐                 │               │
        │      Stage 3           │                 │               │
        │        Plan            │                 │               │
        │                        │                 │               │
        │  terraform plan        │                 │               │
        │  (us-east-1)           │                 │               │
        │  terraform plan        │                 │               │
        │  (eu-west-1)           │                 │               │
        │                        │                 │               │
        │  ⚠️ Requires AWS creds │                 │               │
        └────────────┬───────────┘                 │               │
                     │                             │               │
                     ▼                             │               │
        ┌────────────────────────┐                 │               │
        │      Stage 4           │                 │               │
        │  Test Execution        │                 │               │
        │     Placeholder        │                 │               │
        │                        │                 │               │
        │  📍 Test script execution location      │               │
        │  integration_test.py   │                 │               │
        │                        │                 │               │
        │  ⚠️ Requires AWS creds │                 │               │
        └────────────────────────┘                 │               │
                                                   │               │
                                                   │               │
                                                   │               │
                                                   │               │
                                                   │               │
                                                   │               │
                                                   │               │
                                                   │               │
```

---

### 6.2 Stage Details

| Stage | PRD Requirement | Tool | Check Content | Requires AWS Creds |
|-------|-----------------|------|---------------|-------------------|
| **1. Lint/Validate** | Run standard IaC formatting and validation checks | `terraform fmt` + `terraform validate` | Code format, syntax correctness (both regions) | ❌ No |
| **2. Security Scan** | Integrate a lightweight open-source static analysis tool | `tfsec` | Security vulnerability scan (excluding .terraform directory) | ❌ No |
| **3. Plan** | Generate an infrastructure plan/diff | `terraform plan` | Change preview (both regions in parallel) | ✅ Yes |
| **4. Test Placeholder** | Add a step showing where automated test script would execute post-deployment | - | Test execution location placeholder | ✅ Yes |

---

### 6.3 Workflow Configuration File

```yaml
# .github/workflows/validate.yml
name: Terraform CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  TF_VERSION: "1.7.0"

jobs:
  # ============================================================================
  # Stage 1: Lint/Validate
  # PRD: Run standard IaC formatting and validation checks
  # ============================================================================
  lint-validate:
    name: "Lint & Validate"
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init (us-east-1)
        run: cd terraform/us-east-1 && terraform init -backend=false

      - name: Terraform Init (eu-west-1)
        run: cd terraform/eu-west-1 && terraform init -backend=false

      - name: Terraform Validate (us-east-1)
        run: cd terraform/us-east-1 && terraform validate

      - name: Terraform Validate (eu-west-1)
        run: cd terraform/eu-west-1 && terraform validate

  # ============================================================================
  # Stage 2: Security Scan
  # PRD: Integrate a lightweight open-source static analysis tool (tfsec)
  # ============================================================================
  security-scan:
    name: "Security Scan (tfsec)"
    runs-on: ubuntu-latest
    needs: lint-validate
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          soft_fail: false
          # Exclude downloaded .terraform module directories

  # ============================================================================
  # Stage 3: Plan
  # PRD: Generate an infrastructure plan/diff
  # Note: Requires AWS credentials to execute
  # ============================================================================
  plan:
    name: "Plan (${{ matrix.region }})"
    runs-on: ubuntu-latest
    needs: [lint-validate, security-scan]
    strategy:
      matrix:
        region: [us-east-1, eu-west-1]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: cd terraform/${{ matrix.region }} && terraform init
        # Note: Requires AWS credentials to access S3 backend

      - name: Terraform Plan
        id: plan
        run: |
          cd terraform/${{ matrix.region }}
          terraform plan -out=tfplan -input=false
        continue-on-error: true
        # Note: Will fail without AWS credentials - this is expected per PRD
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ matrix.region }}
          path: terraform/${{ matrix.region }}/tfplan
          retention-days: 7

  # ============================================================================
  # Stage 4: Test Execution Placeholder
  # PRD: Add a step showing where your automated test script would execute
  # Note: This is a placeholder - requires AWS credentials and deployed infrastructure
  # ============================================================================
  test-placeholder:
    name: "Test Execution (Post-Deployment)"
    runs-on: ubuntu-latest
    needs: plan
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Test Dependencies
        run: |
          cd tests
          pip install -r requirements.txt

      - name: Run Integration Tests (Placeholder)
        run: |
          echo "=========================================="
          echo "🧪 INTEGRATION TEST PLACEHOLDER"
          echo "=========================================="
          echo ""
          echo "This step shows where the automated test"
          echo "script (tests/integration_test.py) would"
          echo "execute after successful deployment."
          echo ""
          echo "Test would verify:"
          echo "  1. Cognito authentication (JWT token)"
          echo "  2. us-east-1 /greet endpoint"
          echo "  3. us-east-1 /dispatch endpoint"
          echo "  4. eu-west-1 /greet endpoint"
          echo "  5. eu-west-1 /dispatch endpoint"
          echo "  6. SNS message delivery"
          echo "  7. Response latency comparison"
          echo ""
          echo "To execute tests manually:"
          echo "  cd tests"
          echo "  python integration_test.py \\"
          echo "    --email \$TEST_EMAIL \\"
          echo "    --password \$TEST_PASSWORD"
          echo ""
          echo "=========================================="
        # Note: Actual test execution commented out below
        # Requires: AWS credentials, deployed infrastructure, Cognito test user
        #
        # env:
        #   COGNITO_USER_POOL_ID: ${{ secrets.COGNITO_USER_POOL_ID }}
        #   COGNITO_CLIENT_ID: ${{ secrets.COGNITO_CLIENT_ID }}
        #   API_URL_US_EAST_1: ${{ secrets.API_URL_US_EAST_1 }}
        #   API_URL_EU_WEST_1: ${{ secrets.API_URL_EU_WEST_1 }}
        # run: |
        #   cd tests
        #   python integration_test.py \
        #     --email ${{ secrets.TEST_EMAIL }} \
        #     --password ${{ secrets.TEST_PASSWORD }}
```

---

### 6.4 Key Design Notes

| Design Point | Description |
|--------------|-------------|
| **Backend=false for Init (Stage 1)** | Lint/Validate stage doesn't need to connect to S3 backend, uses `-backend=false` for faster execution |
| **tfsec with exclusions** | Excludes `.terraform/` directory to avoid scanning downloaded third-party modules |
| **Matrix Strategy (Stage 3)** | Plans for both regions execute in parallel for efficiency |
| **continue-on-error: true (Plan)** | PRD allows not providing AWS credentials, Plan failure doesn't block the workflow |
| **Test Placeholder (Stage 4)** | Only shows test execution location, doesn't actually execute (requires deployed infrastructure) |

---

### 6.5 PRD Requirements Mapping

| PRD Requirement | Implementation | File Location |
|-----------------|----------------|---------------|
| Lint/Validate | `terraform fmt -check` + `terraform validate` | Stage 1 |
| Security Scan | `aquasecurity/tfsec-action@v1.0.3` | Stage 2 |
| Plan | `terraform plan -out=tfplan` (both regions) | Stage 3 |
| Test Execution Placeholder | Commented test step + execution instructions | Stage 4 |

---

### 6.6 Notes

> **Note from PRD:** "You do not need to provide AWS credentials to the CI/CD runner; we simply want to review your pipeline architecture and syntax."

- **Stage 1 & 2:** Don't require AWS credentials, can execute successfully
- **Stage 3 (Plan):** Requires AWS credentials, but set `continue-on-error: true` to allow failure
- **Stage 4 (Test):** Only shows architecture, doesn't actually execute tests

---

## 7. Code Review Gates

### Decision: IaC Agent Self-Check + Test Agent Validation

| Gate | Responsible Agent | Check Content | Tools |
|------|-------------------|---------------|-------|
| **Code Self-Check** | IaC Agent | Format, syntax, security | fmt + validate + tfsec |
| **Functional Validation** | Test Agent | End-to-end functionality | Test scripts |

**Pass Criteria:**
- terraform fmt with no errors
- terraform validate with no errors
- tfsec with no critical/high vulnerabilities
- All test scripts pass

---

## 8. Test Pyramid / Validation Flow

### Decision: Unit Test Sufficient

```
        ┌─────────────┐
        │  Unit Test   │  ← terraform validate + tfsec
        └─────────────┘

        ┌─────────────┐
        │  E2E Test    │  ← Test script: concurrent calls to 4 APIs
        └─────────────┘     Validate responses, SNS messages, latency
```

**Test Script Validation Content:**
1. Cognito login successful
2. 4 API endpoints concurrent calls successful
3. Region field in responses correct
4. 4 SNS messages sent successfully
5. Latency data recorded completely

**Test Workflow:**
```bash
# 1. Create virtual environment and install dependencies
cd tests
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Get configuration from Terraform outputs
cd ../terraform/us-east-1
API_URL_USEAST=$(terraform output -raw api_gateway_url)
COGNITO_POOL_ID=$(terraform output -raw cognito_pool_id)
COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)

cd ../eu-west-1
API_URL_EUWEST=$(terraform output -raw api_gateway_url)

# 3. Run test script (set environment variables or modify configuration)
cd ../tests
export COGNITO_USER_POOL_ID="$COGNITO_POOL_ID"
export COGNITO_CLIENT_ID="$COGNITO_CLIENT_ID"
export API_URL_US_EAST_1="$API_URL_USEAST"
export API_URL_EU_WEST_1="$API_URL_EUWEST"

python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

---

## 9. Release / Rollback

### Decision: Simple and Direct

| Operation | Method |
|-----------|--------|
| **Release** | Commit to GitHub main branch |
| **Rollback** | `terraform destroy` + `terraform apply` to redeploy |
| **Multi-Version** | Not needed |

**Release Workflow:**
```
1. Local tests pass
2. git add .
3. git commit -m "feat: implement /greet endpoint"
4. git push
```

**Rollback Workflow:**
```
1. terraform destroy  # Destroy failed deployment
2. Fix issues
3. terraform apply   # Redeploy
```

---

## 10. Complete Workflow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                   Complete Development to Deployment Workflow    │
└─────────────────────────────────────────────────────────────────┘

  1. Team Lead assigns task
         │
         ▼
  2. IaC Agent writes code
         │
         ├─► terraform fmt + validate + tfsec (local self-check)
         │
         ▼
  3. git commit + push
         │
         ▼
  4. CI/CD automatic validation (GitHub Actions)
         │
         ├─► Lint/Validate passed?
         ├─► Security Scan passed?
         ├─► Plan successful?
         │
         ▼
  5. Deploy to AWS
         │
         ├─► cd us-east-1 && terraform apply
         ├─► Manually copy Cognito configuration
         └─► cd eu-west-1 && terraform apply
         │
         ▼
  6. Test Agent validates
         │
         ├─► Run test scripts
         ├─► Check SNS message sending
         │
         ▼
  7. Validation passed?
  ├─ Yes → Doc Agent writes documentation → Complete
  │
  └─ No → IaC Agent fixes → Return to step 2
```

---

## 11. Key Commands Reference

```bash
# Terraform commands
terraform fmt              # Format
terraform fmt -check       # Check format
terraform validate         # Validate syntax
terraform init            # Initialize
terraform plan            # Preview changes
terraform apply           # Deploy
terraform destroy         # Destroy

# Security scan
tfsec .                    # Scan for security issues

# Test
python tests/integration_test.py
```

---

*Document Version: 1.0*
*Created: 2026-03-02*
