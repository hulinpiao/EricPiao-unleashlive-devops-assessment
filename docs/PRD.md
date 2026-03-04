# AWS DevOps Assessment - PRD
## Product Requirements Document

---

## 1. 项目概述

### 1.1 项目名称
Unleash live - AWS DevOps Engineer Skill Assessment

### 1.2 项目目标
构建一个多区域AWS基础设施，展示以下能力：
- IaC（基础设施即代码）最佳实践
- 多区域部署架构设计
- 身份验证与安全配置
- 成本优化的容器编排
- 自动化测试与CI/CD

### 1.3 约束条件
- 时间限制：3小时
- 区域要求：us-east-1 + eu-west-1
- 提交截止：2026年3月15日
- 完成后必须立即销毁资源

---

## 2. 技术栈

| 组件 | 技术选择 |
|------|----------|
| IaC 工具 | Terraform |
| 版本控制 | Git + GitHub |
| CI/CD | GitHub Actions |
| 测试语言 | Python |
| 安全扫描 | tfsec |

---

## 3. 功能需求

### 3.1 身份验证模块 (us-east-1)

| 需求 ID | AUTH-001 |
|---------|----------|
| **目标** | 创建集中式身份验证服务，两个区域共享 |
| **核心组件** | Cognito User Pool + Client + 测试用户 |
| **部署区域** | us-east-1 only |

**功能概要:**
- 创建用户池和客户端配置
- 使用候选人真实邮箱创建测试用户
- 支持用户登录并获取 JWT Token

---

### 3.2 计算与数据模块 (多区域)

| 需求 ID | COMPUTE-001 |
|---------|-------------|
| **目标** | 在两个区域部署相同架构 |
| **部署区域** | us-east-1 + eu-west-1 |

**组件概览:**

| 组件 | 功能 | 说明 |
|------|------|------|
| **API Gateway** | 入口路由 | 提供 /greet 和 /dispatch 两个端点，使用 Cognito 保护 |
| **Lambda 1** | /greet 处理器 | 写 DynamoDB + 发 SNS + 返回区域名 |
| **Lambda 2** | /dispatch 处理器 | 触发 ECS Fargate 任务 |
| **DynamoDB** | 数据存储 | GreetingLogs 表，存储调用记录 |
| **ECS Fargate** | 容器任务 | 由 Lambda 2 触发，执行后发 SNS 消息 |

---

### 3.3 测试模块

| 需求 ID | TEST-001 |
|---------|----------|
| **目标** | 验证多区域部署和性能对比 |
| **测试方式** | Python 脚本并发调用 4 个端点 |

**测试流程概要:**
1. 使用候选人邮箱登录 Cognito，获取 JWT
2. 并发调用两个区域的所有端点
3. 验证响应中的区域字段正确性
4. 测量并对比两个区域的延迟差异

---

### 3.4 CI/CD 模块

| 需求 ID | CICD-001 |
|---------|----------|
| **目标** | 定义基础设施自动化流程 |
| **平台** | GitHub Actions |

**流水线步骤:**
| 步骤 | 工具 | 目的 |
|------|------|------|
| Lint/Validate | terraform fmt/validate | 代码规范检查 |
| Security Scan | tfsec | 安全漏洞扫描 |
| Plan | terraform plan | 生成变更预览 |
| Test (Placeholder) | - | 展示测试执行位置 |

---

### 3.5 功能流程图

```
┌──────────────────────────────────────────────────────────────────┐
│                         测试客户端                                 │
│                    (Python 测试脚本)                              │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Cognito (us-east-1)                          │
│                       身份验证                                   │
│                    获取 JWT Token                                │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│       us-east-1           │   │       eu-west-1           │
│  ┌─────────────────────┐  │   │  ┌─────────────────────┐  │
│  │   API Gateway       │  │   │  │   API Gateway       │  │
│  │   /greet            │  │   │  │   /greet            │  │
│  │   /dispatch         │  │   │  │   /dispatch         │  │
│  └──────────┬──────────┘  │   │  └──────────┬──────────┘  │
│             │               │   │             │               │
│      ┌──────┴──────┐        │   │      ┌──────┴──────┐        │
│      ▼             ▼        │   │      ▼             ▼        │
│  ┌─────────┐  ┌─────────┐   │   │  ┌─────────┐  ┌─────────┐   │
│  │ Lambda  │  │ Lambda  │   │   │  │ Lambda  │  │ Lambda  │   │
│  │  Greet   │  │Dispatch │   │   │  │  Greet   │  │Dispatch │   │
│  └────┬────┘  └────┬────┘   │   │  └────┬────┘  └────┬────┘   │
│       │            │         │   │       │            │         │
│       ▼            ▼         │   │       ▼            ▼         │
│  ┌─────────┐  ┌─────┐      │   │  ┌─────────┐  ┌─────┐      │
│  │DynamoDB │  │ ECS │      │   │  │DynamoDB │  │ ECS │      │
│  └─────────┘  └─────┘      │   │  └─────────┘  └─────┘      │
└───────────────────────────┘   └───────────────────────────┘
         │                              │
         └──────────────┬───────────────┘
                        ▼
            ┌───────────────────────┐
            │   SNS Topic            │
            │  (us-east-1)           │
            │   发送验证消息          │
            └───────────────────────┘
```

---

## 4. SNS 集成规范

### 4.1 Topic ARN

SNS Topic 用于验证 | `arn:aws:sns:us-east-1:160676960050:Candidate-Verification-Topic` 

### 4.2 Payload 格式

**Lambda 发送的 Payload:**
```json
{
  "email": "candidate@example.com",
  "source": "Lambda",
  "region": "us-east-1",
  "repo": "https://github.com/candidate/aws-assessment"
}
```

**ECS 发送的 Payload:**
```json
{
  "email": "candidate@example.com",
  "source": "ECS",
  "region": "eu-west-1",
  "repo": "https://github.com/candidate/aws-assessment"
}
```

---

## 5. 安全要求

| 组件 | 安全要求 | 来源 |
|------|----------|------|
| **API Gateway** | 使用 Cognito User Pool 进行身份验证 | PDF 要求 |
| **SNS** | 发布消息到指定的 Verification Topic | PDF 要求 |
| **Lambda** | 使用最小权限 IAM Role（仅授予 DynamoDB 写入和 SNS 发布权限） | 最佳实践 |
| **ECS Fargate** | Task Role 使用最小权限（仅授予 SNS 发布权限） | 最佳实践 |

---

## 6. 成本优化

| 组件 | 优化策略 |
|------|----------|
| ECS Fargate | 使用公共子网，避免 NAT Gateway |
| Lambda | 按实际使用配置内存和超时 |
| DynamoDB | 按需计费模式 |
| API Gateway | 按使用计费（无需额外优化） |

---

## 7. 验收标准

### 7.1 基础设施验收

#### 部署成功检查
```
执行命令: terraform apply

预期结果:
✅ us-east-1 资源创建成功
✅ eu-west-1 资源创建成功
✅ 无错误或警告
```

#### 组件可用性检查

| 组件 | 验证方式 | 预期结果 |
|------|----------|----------|
| Cognito | 使用测试用户登录 | 成功获取 JWT Token |
| API Gateway (us-east-1) | 带JWT调用 /greet | 返回 200 + "us-east-1" |
| API Gateway (eu-west-1) | 带JWT调用 /greet | 返回 200 + "eu-west-1" |
| DynamoDB | 检查表项 | GreetingLogs 有新记录 |
| ECS Fargate | 调用 /dispatch | 任务启动并完成 |

---

### 7.2 测试脚本验收

#### 测试前准备

| 步骤 | 说明 |
|------|------|
| 1 | 确保两个区域的基础设施已部署完成 |
| 2 | 获取 Cognito 测试用户的邮箱和临时密码 |
| 3 | 确认测试脚本的依赖已安装 (`pip install -r requirements.txt`) |

#### 测试执行

```bash
# 运行测试脚本
cd tests
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

#### 测试覆盖范围

```
测试脚本将验证以下内容：

┌─────────────────────────────────────────────────────────────────┐
│                        测试矩阵                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   us-east-1     │    │   eu-west-1     │                    │
│  ├─────────────────┤    ├─────────────────┤                    │
│  │ /greet  (Lambda)│    │ /greet  (Lambda)│                    │
│  │ /dispatch (ECS) │    │ /dispatch (ECS) │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                            │
│           └───────────┬───────────┘                            │
│                       ▼                                        │
│              ┌──────────────────────┐                          │
│              │   验证点：            │                          │
│              │   1. 响应状态码 200   │                          │
│              │   2. region 字段正确   │                          │
│              │   3. SNS 消息发送成功  │                          │
│              │   4. 延迟数据记录      │                          │
│              └──────────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

#### 预期输出

```
=== 测试报告 ===

[1] 身份验证
  ✅ Cognito 登录成功
  JWT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

[2] API 调用测试
  端点                          状态    延迟      Region
  ──────────────────────────────────────────────────────
  us-east-1  /greet            ✅      245ms    us-east-1
  us-east-1  /dispatch         ✅     1850ms    us-east-1
  eu-west-1  /greet            ✅      389ms    eu-west-1
  eu-west-1  /dispatch         ✅     2100ms    eu-west-1

[3] 性能分析
  Lambda 延迟对比:
    us-east-1: 245ms
    eu-west-1: 389ms
    差异: +144ms (eu-west-1 慢 58.8%)

  ECS 延迟对比:
    us-east-1: 1850ms
    eu-west-1: 2100ms
    差异: +250ms (eu-west-1 慢 13.5%)

[4] SNS 验证
  ✅ 4/4 消息已发送至 Unleash live Topic
  ✅ 检查邮箱以接收确认通知

=== 测试完成 ===
总耗时: 8.2秒
```

#### 测试验收标准

| 检查项 | 通过标准 |
|--------|----------|
| 并发调用 | 4 个端点全部成功调用 |
| 状态码 | 所有 API 返回 200 |
| Region 验证 | 响应中的 region 字段与请求区域一致 |
| SNS 发送 | Unleash live 收到 4 条消息 |
| 延迟输出 | 控制台输出完整的延迟对比数据 |

---

### 7.3 SNS 消息验收

#### 如何确认 SNS 发送成功？

**方式 1: 通过测试脚本输出**
```
测试脚本会显示类似输出：
✅ 4/4 消息已发送至 Unleash live Topic
```

**方式 2: 等待招聘团队确认**
- Unleash live 会自动监控 SNS Topic
- 如果消息格式正确，他们会收到通知
- 通过技术审核的候选人会在截止日期后收到面试邀请

#### SNS 消息格式要求

测试脚本触发的每条消息必须包含：

| 字段 | 说明 | 示例 |
|------|------|------|
| email | 候选人邮箱 | `candidate@example.com` |
| source | 消息来源 | `Lambda` 或 `ECS` |
| region | 执行区域 | `us-east-1` 或 `eu-west-1` |
| repo | GitHub 仓库 | `https://github.com/user/aws-assessment` |

---

### 7.4 CI/CD 验收

#### GitHub Actions 工作流验证

```bash
# 推送代码后，在 GitHub Actions 页面检查
```

**验证清单:**

| 步骤 | 检查内容 |
|------|----------|
| Lint | 代码格式化检查通过 |
| Security Scan | tfsec 无严重/高危漏洞 |
| Plan | terraform plan 成功生成预览 |

---

### 7.5 文档验收

#### README.md 必需内容

| 章节 | 内容要求 |
|------|----------|
| 项目简介 | 简要说明这是一个 AWS DevOps Assessment |
| 架构图 | 展示两个区域的部署架构 |
| 前置条件 | AWS CLI、Terraform、Python 等工具版本 |
| 部署步骤 | `terraform init` → `apply` 的完整命令 |
| 测试说明 | 如何运行测试脚本、需要什么参数 |
| 清理说明 | `terraform destroy` 命令和注意事项 |

---

## 8. 交付方式

### 8.1 交付清单

| 文件/目录 | 说明 | 必需 |
|-----------|------|------|
| `terraform/` | IaC 代码（包含 main.tf, providers.tf, variables.tf, outputs.tf, backend.tf） | ✅ |
| `terraform/modules/` | Terraform 模块（cognito, regional-stack） | ✅ |
| `terraform/environments/` | 环境配置文件（us-east-1, eu-west-1） | ✅ |
| `tests/integration_test.py` | 测试脚本 | ✅ |
| `tests/requirements.txt` | Python 依赖 | ✅ |
| `.github/workflows/deploy.yml` | CI/CD 配置 | ✅ |
| `README.md` | 使用文档 | ✅ |

### 8.2 提交检查清单

在提交仓库链接前，确认以下事项：
- [ ] 仓库是公开的 (Public)
- [ ] README.md 包含完整的部署和测试说明
- [ ] 测试脚本可以成功运行
- [ ] SNS 消息已成功发送（4条）
- [ ] 资源已销毁（terraform destroy）
- [ ] 代码提交记录清晰

---

## 9. 重要提醒

⚠️ **资源清理：**
测试完成后必须执行 `terraform destroy` 避免持续费用

📧 **验证方式：**
通过 SNS Topic 接收的消息自动验证完成情况

📅 **截止日期：**
2026年3月15日

---

*文档版本: 3.0*
*创建日期: 2026-03-02*
*最后更新: 2026-03-02*
