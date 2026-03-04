# Phase 6: CI/CD Configuration

**Estimated Time:** 15 minutes
**Responsible Agent:** Team Lead
**Dependencies:** None (can run in parallel)
**Status:** ⏳ Pending

---

## Phase Objective

Create GitHub Actions workflow for automated validation.

> **PRD Requirement:** A DevOps engineer doesn't deploy from their laptop. Include a CI/CD pipeline configuration file that defines automated steps.

---

## PRD Requirements Mapping

| PRD Requirement | Implementation | Stage |
|-----------------|----------------|-------|
| Lint/Validate | `terraform fmt -check` + `terraform validate` | Stage 1 |
| Security Scan | `aquasecurity/tfsec-action@v1.0.3` | Stage 2 |
| Plan | `terraform plan -out=tfplan` (both regions) | Stage 3 |
| Test Execution Placeholder | Commented test step + execution instructions | Stage 4 |

---

## Task List

### CICD-001: Create GitHub Actions Workflow

| Field | Content |
|-------|---------|
| **Task ID** | `CICD-001` |
| **Status** | ⏳ |
| **Owner** | Team Lead |
| **Description** | Create CI/CD pipeline configuration file `.github/workflows/validate.yml` with 4 Stages |
| **Deliverable** | `.github/workflows/validate.yml` |
| **Acceptance Criteria** | Correct YAML syntax, includes 4 Stages, meets PRD requirements |

---

## Pipeline Architecture

```
Trigger: push / pull_request to main
                │
                ▼
┌─────────────────────────────────┐
│  Stage 1: Lint/Validate         │  ← terraform fmt + validate (both regions)
│  ❌ No AWS credentials required │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│  Stage 2: Security Scan         │  ← tfsec scan for security vulnerabilities
│  ❌ No AWS credentials required │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│  Stage 3: Plan                  │  ← terraform plan (both regions in parallel)
│  ⚠️ AWS credentials required   │
│  (continue-on-error: true)      │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│  Stage 4: Test Placeholder      │  ← Test execution position placeholder
│  ⚠️ AWS credentials required   │
│  (architecture demo only,       │
│   not actually executed)        │
└─────────────────────────────────┘
```

---

## Workflow Configuration

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
  # Stage 1: Lint/Validate
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

  # Stage 2: Security Scan
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

  # Stage 3: Plan
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

      - name: Terraform Plan
        run: |
          cd terraform/${{ matrix.region }}
          terraform plan -out=tfplan -input=false
        continue-on-error: true
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ matrix.region }}
          path: terraform/${{ matrix.region }}/tfplan
          retention-days: 7

  # Stage 4: Test Execution Placeholder
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
          echo "INTEGRATION TEST PLACEHOLDER"
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
          echo "=========================================="
```

---

## Acceptance Criteria

- [ ] `.github/workflows/validate.yml` file created
- [ ] Correct YAML syntax
- [ ] Includes 4 Stages (Lint/Validate, Security Scan, Plan, Test Placeholder)
- [ ] Stage 1 & 2 do not require AWS credentials
- [ ] Stage 3 & 4 have `continue-on-error` set or are placeholders

---

## Notes

> **PRD Note:** "You do not need to provide AWS credentials to the CI/CD runner; we simply want to review your pipeline architecture and syntax."

- Stage 1 & 2 can execute successfully (no credentials required)
- Stage 3 (Plan) will fail due to missing credentials, but this is expected
- Stage 4 is just a placeholder showing test execution position

---

## Next Phase

After completion, proceed to **[Phase 7: Documentation](../07-docs/plan.md)**

---

*Last Updated: 2026-03-04*
