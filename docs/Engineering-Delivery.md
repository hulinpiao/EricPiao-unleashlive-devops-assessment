# Engineering Delivery / Dev Workflow

## Vibe Coding 阶段 - Team Agents 协作指南

---

## 1. Repo Structure

### 决策：Monorepo

```
aws-assessment/
├── terraform/
│   ├── modules/              # 共享模块
│   │   ├── api-gateway/
│   │   ├── lambda-greet/
│   │   ├── lambda-dispatch/
│   │   ├── dynamodb/
│   │   ├── ecs-fargate/
│   │   └── cognito/
│   ├── us-east-1/           # us-east-1 区域部署
│   │   ├── main.tf          # 主配置
│   │   ├── backend.tf
│   │   ├── providers.tf
│   │   ├── cognito.tf       # Cognito 模块调用
│   │   ├── greet.tf         # /greet 相关模块
│   │   ├── dispatch.tf      # /dispatch 相关模块
│   │   ├── api-gateway.tf   # API Gateway 模块
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   └── eu-west-1/           # eu-west-1 区域部署
│       ├── main.tf          # 主配置
│       ├── backend.tf
│       ├── providers.tf
│       ├── greet.tf         # /greet 相关模块
│       ├── dispatch.tf      # /dispatch 相关模块
│       ├── api-gateway.tf   # API Gateway 模块
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
│       └── validate.yml     # CI/CD 流水线
├── README.md
└── .gitignore
```

**理由：** 单一仓库便于管理，代码共享，适合评估项目。

---

## 2. Branching Strategy

### 决策：Trunk-Based Development

```
main (直接提交)
```

**工作流：**
1. 直接在 `main` 分支开发
2. 提交前运行本地检查
3. 提交后 CI/CD 自动验证

**理由：** 评估项目简单直接，无需复杂分支管理。

---

## 3. Environment Strategy

### 决策：单一环境

**实际情况：** 只有一个部署环境，通过切换 SNS Topic ARN 区分开发/验收阶段

| 阶段 | SNS Topic ARN | terraform.tfvars |
|------|---------------|-------------------|
| **开发/验收** | `arn:aws:sns:us-east-1:160676960050:Candidate-Verification-Topic` | `sns_topic_arn = "arn:..."` |

**切换方式：** 手动修改 `terraform.tfvars` 中的 `sns_topic_arn` 变量

---

## 4. Local Dev Workflow

### 决策：直接部署 + Plan 排查

```
1. 编辑 Terraform 代码
       │
       ▼
2. terraform fmt          # 格式化
       │
       ▼
3. terraform init         # 初始化
       │
       ▼
4. terraform plan         # 预览变更
       │
       ▼
5. terraform apply        # 部署到 AWS
       │
       ▼
6. 运行测试脚本验证
       │
       ▼
7. 根据结果调整
       │
       └──► 失败 → terraform plan 排查 → 重新部署
```

**部署失败排查：** `terraform plan` 查看报错信息

---

## 5. AI Agent Roles

### 决策：4 个角色

| Agent | 职责 | 兼任 |
|-------|------|------|
| **Team Lead / Planner** | 任务分配、进度跟踪、协调 | - |
| **IaC Agent / Reviewer** | 编写 Terraform 代码、代码审查、自检 | 兼任 Reviewer |
| **Test Agent** | 编写测试脚本、验证功能 | - |
| **Doc Agent** | 编写 README、文档 | - |

### Agent 协作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      Vibe Coding 流程                           │
└─────────────────────────────────────────────────────────────────┘

  Team Lead 分配任务
        │
        ▼
  IaC Agent 编写代码
        │
        ├─► terraform fmt + validate + tfsec (自检)
        │
        ▼
  Test Agent 验证功能
        │
        ├─► 运行测试脚本
        │
        ▼
  验证通过？
  ├─ 是 → Doc Agent 编写文档
  │         │
  │         ▼
  │    完成任务
  │
  └─ 否 → IaC Agent 修复问题
             │
             └──► 重新验证
```

---

## 6. CI/CD Stages

### 决策：按 PRD 要求，4 个 Stages

> **PRD 要求：** A DevOps engineer doesn't deploy from their laptop. Include a CI/CD pipeline configuration file that defines automated steps.

---

### 6.1 Pipeline 架构图

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
│ (两个区域)    │         │               │         │               │
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
        │  ⚠️ 需要 AWS creds     │                 │               │
        └────────────┬───────────┘                 │               │
                     │                             │               │
                     ▼                             │               │
        ┌────────────────────────┐                 │               │
        │      Stage 4           │                 │               │
        │  Test Execution        │                 │               │
        │     Placeholder        │                 │               │
        │                        │                 │               │
        │  📍 测试脚本执行位置    │                 │               │
        │  integration_test.py   │                 │               │
        │                        │                 │               │
        │  ⚠️ 需要 AWS creds     │                 │               │
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

### 6.2 各 Stage 详细说明

| Stage | PRD 要求 | 工具 | 检查内容 | 需要 AWS Creds |
|-------|----------|------|----------|----------------|
| **1. Lint/Validate** | Run standard IaC formatting and validation checks | `terraform fmt` + `terraform validate` | 代码格式、语法正确性（两个区域） | ❌ 不需要 |
| **2. Security Scan** | Integrate a lightweight open-source static analysis tool | `tfsec` | 安全漏洞扫描（排除 .terraform 目录） | ❌ 不需要 |
| **3. Plan** | Generate an infrastructure plan/diff | `terraform plan` | 变更预览（两个区域并行） | ✅ 需要 |
| **4. Test Placeholder** | Add a step showing where automated test script would execute post-deployment | - | 测试执行位置占位符 | ✅ 需要 |

---

### 6.3 工作流配置文件

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
          # 排除下载的 .terraform 模块目录

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

### 6.4 关键设计说明

| 设计点 | 说明 |
|--------|------|
| **Backend=false for Init (Stage 1)** | Lint/Validate 阶段不需要连接 S3 backend，使用 `-backend=false` 加速执行 |
| **tfsec with exclusions** | 排除 `.terraform/` 目录，避免扫描下载的第三方模块 |
| **Matrix Strategy (Stage 3)** | 两个区域的 Plan 并行执行，提高效率 |
| **continue-on-error: true (Plan)** | PRD 允许不提供 AWS credentials，Plan 失败不阻塞流程 |
| **Test Placeholder (Stage 4)** | 只展示测试执行位置，不真正执行（需要已部署的基础设施） |

---

### 6.5 PRD 要求对照

| PRD 要求 | 实现方式 | 文件位置 |
|----------|----------|----------|
| Lint/Validate | `terraform fmt -check` + `terraform validate` | Stage 1 |
| Security Scan | `aquasecurity/tfsec-action@v1.0.3` | Stage 2 |
| Plan | `terraform plan -out=tfplan` (两个区域) | Stage 3 |
| Test Execution Placeholder | 带注释的测试步骤 + 执行说明 | Stage 4 |

---

### 6.6 注意事项

> **Note from PRD:** "You do not need to provide AWS credentials to the CI/CD runner; we simply want to review your pipeline architecture and syntax."

- **Stage 1 & 2**：不需要 AWS credentials，可以成功执行
- **Stage 3 (Plan)**：需要 AWS credentials，但设置 `continue-on-error: true` 允许失败
- **Stage 4 (Test)**：只展示架构，不真正执行测试

---

## 7. Code Review Gates

### 决策：IaC Agent 自查 + Test Agent 验证

| Gate | 责任 Agent | 检查内容 | 工具 |
|------|------------|----------|------|
| **代码自检** | IaC Agent | 格式、语法、安全 | fmt + validate + tfsec |
| **功能验证** | Test Agent | 端到端功能 | 测试脚本 |

**通过标准：**
- terraform fmt 无错误
- terraform validate 无错误
- tfsec 无严重/高危漏洞
- 测试脚本全部通过

---

## 8. Test Pyramid / Validation Flow

### 决策：Unit Test 足够

```
        ┌─────────────┐
        │  Unit Test   │  ← terraform validate + tfsec
        └─────────────┘

        ┌─────────────┐
        │  E2E Test    │  ← 测试脚本：并发调用 4 个 API
        └─────────────┘     验证响应、SNS 消息、延迟
```

**测试脚本验证内容：**
1. Cognito 登录成功
2. 4 个 API 端点并发调用成功
3. 响应中的 region 字段正确
4. 4 条 SNS 消息发送成功
5. 延迟数据记录完整

**测试流程：**
```bash
# 1. 创建虚拟环境并安装依赖
cd tests
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. 从 Terraform outputs 获取配置
cd ../terraform/us-east-1
API_URL_USEAST=$(terraform output -raw api_gateway_url)
COGNITO_POOL_ID=$(terraform output -raw cognito_pool_id)
COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)

cd ../eu-west-1
API_URL_EUWEST=$(terraform output -raw api_gateway_url)

# 3. 运行测试脚本（设置环境变量或修改配置）
cd ../tests
export COGNITO_USER_POOL_ID="$COGNITO_POOL_ID"
export COGNITO_CLIENT_ID="$COGNITO_CLIENT_ID"
export API_URL_US_EAST_1="$API_URL_USEAST"
export API_URL_EU_WEST_1="$API_URL_EUWEST"

python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

---

## 9. Release / Rollback

### 决策：简单直接

| 操作 | 方式 |
|------|------|
| **Release** | 提交到 GitHub 主分支 |
| **Rollback** | `terraform destroy` + `terraform apply` 重新部署 |
| **多版本** | 不需要 |

**Release 流程：**
```
1. 本地测试通过
2. git add .
3. git commit -m "feat: implement /greet endpoint"
4. git push
```

**Rollback 流程：**
```
1. terraform destroy  # 销毁失败的部署
2. 修复问题
3. terraform apply   # 重新部署
```

---

## 10. 完整工作流总结

```
┌─────────────────────────────────────────────────────────────────┐
│                   开发到部署完整流程                            │
└─────────────────────────────────────────────────────────────────┘

  1. Team Lead 分配任务
         │
         ▼
  2. IaC Agent 编写代码
         │
         ├─► terraform fmt + validate + tfsec (本地自检)
         │
         ▼
  3. git commit + push
         │
         ▼
  4. CI/CD 自动验证 (GitHub Actions)
         │
         ├─► Lint/Validate 通过？
         ├─► Security Scan 通过？
         ├─► Plan 成功？
         │
         ▼
  5. 部署到 AWS
         │
         ├─► cd us-east-1 && terraform apply
         ├─► 手动复制 Cognito 配置
         └─► cd eu-west-1 && terraform apply
         │
         ▼
  6. Test Agent 验证
         │
         ├─► 运行测试脚本
         ├─► 检查 SNS 消息发送
         │
         ▼
  7. 验证通过？
  ├─ 是 → Doc Agent 编写文档 → 完成
  │
  └─ 否 → IaC Agent 修复 → 回到步骤 2
```

---

## 11. 关键命令速查

```bash
# Terraform 命令
terraform fmt              # 格式化
terraform fmt -check       # 检查格式
terraform validate         # 验证语法
terraform init            # 初始化
terraform plan            # 预览变更
terraform apply           # 部署
terraform destroy         # 销毁

# 安全扫描
tfsec .                    # 扫描安全问题

# 测试
python tests/integration_test.py
```

---

*文档版本: 1.0*
*创建日期: 2026-03-02*
