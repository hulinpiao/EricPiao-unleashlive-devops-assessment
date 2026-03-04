# CI/CD Pipeline 文档

> GitHub Actions 工作流，用于 Terraform 代码的自动化验证和部署。

---

## 1. Pipeline 流程图

### 自动触发流程（push / PR to main）

```
┌─────────────────────────────────────────────────────────────────┐
│                    代码推送到 main 分支                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 1: Lint & Validate                                       │
│  检查代码格式和语法                                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 2: Security Scan                                         │
│  tfsec 安全漏洞扫描                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 3: Plan                                                  │
│  预览基础设施变更（us-east-1 和 eu-west-1 并行）                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 5: Integration Test                                      │
│  运行集成测试（验证 API 端点）                                     │
└─────────────────────────────────────────────────────────────────┘
```

### 手动触发流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    手动触发 (workflow_dispatch)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ 默认选项       │   │ run_tests_only│   │ apply_changes │
│               │   │ = true        │   │ = true        │
│ 完整流程       │   │               │   │               │
│ Lint→Scan→Plan│   │ 直接执行测试   │   │ 执行部署       │
└───────────────┘   └───────────────┘   └───────────────┘
```

---

## 2. 各 Stage 说明

### Stage 1: Lint & Validate

**作用：** 确保代码格式统一、语法正确

| 检查项 | 工具 | 说明 |
|--------|------|------|
| 格式检查 | `terraform fmt -check` | 检查代码缩进、换行、括号等格式是否符合标准 |
| 语法验证 | `terraform validate` | 检查 Terraform 语法是否正确、资源引用是否有效 |

**为什么需要：**
- 统一代码风格，便于团队协作
- 尽早发现语法错误，避免后续阶段失败
- 不需要 AWS credentials，执行速度快

---

### Stage 2: Security Scan (tfsec)

**作用：** 扫描 Terraform 代码中的安全漏洞和配置问题

**tfsec 检查的规则类别：**

| 类别 | 检查内容 | 示例 |
|------|----------|------|
| **AWS 安全** | S3 存储桶是否公开、安全组是否过于宽松 | 公开的 S3 bucket、允许 0.0.0.0/0 的安全组 |
| **加密** | 数据是否加密存储 | RDS 未启用加密、S3 未启用 server-side encryption |
| **网络** | 网络配置是否安全 | Lambda 在 VPC 外、公开的数据库端口 |
| **IAM** | 权限是否遵循最小权限原则 | 使用 `*:*` 通配符权限 |
| **日志** | 是否启用审计日志 | CloudTrail 未启用、S3 访问日志未启用 |

**为什么需要：**
- 在部署前发现安全隐患
- 遵循安全最佳实践
- 防止生产环境出现安全漏洞

---

### Stage 3: Plan

**作用：** 预览即将执行的基础设施变更

**Plan 会告诉你：**
- `+` 将要创建的资源
- `-` 将要删除的资源
- `~` 将要修改的资源

**为什么需要：**
- 在实际部署前看到变更内容
- 防止意外删除重要资源
- 两个区域（us-east-1、eu-west-1）并行执行，提高效率

**注意：** 此阶段需要 AWS credentials 才能执行

---

### Stage 4: Apply

**作用：** 执行基础设施变更（手动触发）

**触发方式：**
1. 先运行一次默认流程，生成 Plan artifact
2. 然后手动触发 `apply_changes = true`

**可选参数：**
- `apply_region`: 选择部署区域（all / us-east-1 / eu-west-1）

**为什么需要手动触发：**
- 防止意外部署到生产环境
- 给团队审核 Plan 结果的机会
- 符合 DevOps 最佳实践

---

### Stage 5: Integration Test

**作用：** 验证部署的 API 是否正常工作

**测试内容：**
1. Cognito 认证（获取 JWT token）
2. us-east-1 /greet 端点
3. us-east-1 /dispatch 端点
4. eu-west-1 /greet 端点
5. eu-west-1 /dispatch 端点
6. SNS 消息发送
7. 响应延迟对比

---

## 3. Test Execution 特殊架构

> **重要：** Integration Test 支持多种触发方式

```
┌─────────────────────────────────────────────────────────────────┐
│                  Integration Test 触发方式                        │
└─────────────────────────────────────────────────────────────────┘

方式 1: 顺序触发（自动）
┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐
│  Lint  │ ──► │  Scan  │ ──► │  Plan  │ ──► │  Test  │
└────────┘     └────────┘     └────────┘     └────────┘
                                 成功后


方式 2: 手动触发（随时）
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│    手动触发：run_tests_only = true                              │
│                    │                                           │
│                    ▼                                           │
│              ┌────────┐                                        │
│              │  Test  │  ← 跳过所有前置步骤，直接执行测试          │
│              └────────┘                                        │
│                                                                │
└────────────────────────────────────────────────────────────────┘


方式 3: 部署后触发
┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐
│  Plan  │ ──► │ Apply  │ ──► │  Test  │
└────────┘     └────────┘     └────────┘
   (之前)      (手动触发)      (部署成功后自动执行)
```

**使用场景：**

| 场景 | 推荐方式 |
|------|----------|
| 日常开发验证 | 方式 1（自动） |
| 快速回归测试 | 方式 2（手动） |
| 生产环境部署后验证 | 方式 3（部署后） |

---

## 4. 手动触发参数

在 GitHub Actions 页面点击 "Run workflow" 时可配置：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `run_tests_only` | 只运行测试，跳过其他步骤 | `false` |
| `apply_changes` | 执行 terraform apply | `false` |
| `apply_region` | 部署区域 | `all` |
| `environment` | 测试环境 | `development` |

---

## 5. 需要配置的 Secrets

| Secret | 说明 | 必需 |
|--------|------|------|
| `AWS_ACCESS_KEY_ID` | AWS 访问密钥 | Plan/Apply/Test |
| `AWS_SECRET_ACCESS_KEY` | AWS 秘密密钥 | Plan/Apply/Test |
| `COGNITO_USER_POOL_ID` | Cognito Pool ID | Test |
| `COGNITO_CLIENT_ID` | Cognito Client ID | Test |
| `API_URL_US_EAST_1` | us-east-1 API URL | Test |
| `API_URL_EU_WEST_1` | eu-west-1 API URL | Test |
| `TEST_EMAIL` | 测试用户邮箱 | Test |
| `TEST_PASSWORD` | 测试用户密码 | Test |

**配置路径：** GitHub 仓库 → Settings → Secrets and variables → Actions

---

## 6. 本地运行

如果想在本地运行相同的检查：

```bash
# 格式检查
terraform fmt -check -recursive

# 语法验证
cd terraform/us-east-1 && terraform init -backend=false && terraform validate
cd terraform/eu-west-1 && terraform init -backend=false && terraform validate

# 安全扫描（需要安装 tfsec）
tfsec .

# Plan
cd terraform/us-east-1 && terraform init && terraform plan
cd terraform/eu-west-1 && terraform init && terraform plan

# 测试
cd tests && pip install -r requirements.txt
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

---

*文档版本: 1.0*
*更新日期: 2026-03-04*
