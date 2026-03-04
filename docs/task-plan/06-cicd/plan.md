# Phase 6: CI/CD 配置

**预计时间：** 15分钟
**负责 Agent：** Team Lead
**依赖：** 无（可并行进行）
**状态：** ⏳ 待开始

---

## 阶段目标

创建 GitHub Actions 工作流，实现自动化验证。

> **PRD 要求：** A DevOps engineer doesn't deploy from their laptop. Include a CI/CD pipeline configuration file that defines automated steps.

---

## PRD 要求对照

| PRD 要求 | 实现方式 | Stage |
|----------|----------|-------|
| Lint/Validate | `terraform fmt -check` + `terraform validate` | Stage 1 |
| Security Scan | `aquasecurity/tfsec-action@v1.0.3` | Stage 2 |
| Plan | `terraform plan -out=tfplan` (两个区域) | Stage 3 |
| Test Execution Placeholder | 带注释的测试步骤 + 执行说明 | Stage 4 |

---

## 任务清单

### CICD-001: 创建 GitHub Actions 工作流

| 字段 | 内容 |
|------|------|
| **Task ID** | `CICD-001` |
| **Status** | ⏳ |
| **Owner** | Team Lead |
| **Description** | 创建 CI/CD 流水线配置文件 `.github/workflows/validate.yml`，包含 4 个 Stages |
| **Deliverable** | `.github/workflows/validate.yml` |
| **Acceptance Criteria** | YAML 语法正确、包含 4 个 Stages、符合 PRD 要求 |

---

## Pipeline 架构

```
Trigger: push / pull_request to main
                │
                ▼
┌─────────────────────────────────┐
│  Stage 1: Lint/Validate         │  ← terraform fmt + validate (两个区域)
│  ❌ 不需要 AWS credentials      │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│  Stage 2: Security Scan         │  ← tfsec 扫描安全漏洞
│  ❌ 不需要 AWS credentials      │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│  Stage 3: Plan                  │  ← terraform plan (两个区域并行)
│  ⚠️ 需要 AWS credentials        │
│  (continue-on-error: true)      │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│  Stage 4: Test Placeholder      │  ← 测试执行位置占位符
│  ⚠️ 需要 AWS credentials        │
│  (只展示架构，不真正执行)        │
└─────────────────────────────────┘
```

---

## 工作流配置

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

## 验收标准

- [ ] `.github/workflows/validate.yml` 文件已创建
- [ ] YAML 语法正确
- [ ] 包含 4 个 Stages (Lint/Validate, Security Scan, Plan, Test Placeholder)
- [ ] Stage 1 & 2 不需要 AWS credentials
- [ ] Stage 3 & 4 设置 `continue-on-error` 或为 placeholder

---

## 注意事项

> **PRD 说明：** "You do not need to provide AWS credentials to the CI/CD runner; we simply want to review your pipeline architecture and syntax."

- Stage 1 & 2 可以成功执行（不需要 credentials）
- Stage 3 (Plan) 会因缺少 credentials 失败，但这是预期的
- Stage 4 只是占位符，展示测试执行位置

---

## 下一阶段

完成后进入 **[Phase 7: 文档编写](../07-docs/plan.md)**

---

*更新日期: 2026-03-04*
