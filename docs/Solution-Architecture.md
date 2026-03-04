# AWS DevOps Assessment - Solution Architecture

---

## 1. High-Level User Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      用户操作流程                                │
└─────────────────────────────────────────────────────────────────┘

  候选人                          招聘团队
     │                                │
     │ 1. 部署基础设施                 │
     │    - us-east-1 (含 Cognito)    │
     │    - eu-west-1                 │
     │                                │
     │ 2. 运行测试脚本                 │
     │    - Cognito 登录              │
     │    - 并发调用 4 个 API         │
     │                                │
     │ 3. 触发验证消息 ────────────────► 4. 接收 4 条 SNS 消息
     │    - Lambda → SNS (2条)          - 验证候选人信息
     │    - ECS → SNS (2条)             - 技术审核
     │                                    │
     │                                │ 5. 发送面试邀请
     │ 6. 销毁基础设施 ◄───────────────────
     │    - terraform destroy
```

**关键路径：** 登录 → 并发调用 4 个端点 → 发送 4 条 SNS 消息 → 验证

---

## 2. 系统架构图

```
┌──────────────────────────────────────────────────────────────────┐
│                         整体架构                                  │
└──────────────────────────────────────────────────────────────────┘

                    Cognito (us-east-1 only)
                            │
            ┌───────────────┴───────────────┐
            │                               │
            ▼                               ▼
    ┌───────────────┐               ┌───────────────┐
    │   us-east-1   │               │   eu-west-1   │
    │               │               │               │
    │  API Gateway  │               │  API Gateway  │
    │  /greet       │               │  /greet       │
    │  /dispatch    │               │  /dispatch    │
    │      │        │               │      │        │
    │  ┌───┴───┐   │               │  ┌───┴───┐   │
    │  │ Lambda│   │               │  │ Lambda│   │
    │  │  +DDB │   │               │  │  +DDB │   │
    │  │  +SNS │   │               │  │  +SNS │   │
    │  └───┬───┘   │               │  └───┬───┘   │
    │      │        │               │      │        │
    │  ┌───┴───┐   │               │  ┌───┴───┐   │
    │  │  ECS  │   │               │  │  ECS  │   │
    │  │  +SNS  │   │               │  │  +SNS  │   │
    │  └───────┘   │               │  └───────┘   │
    └───────┬───────┘               └───────┬───────┘
            │                               │
            └──────────────┬────────────────┘
                           ▼
                    SNS Topic (us-east-1)
```

---

## 3. 项目结构

```
terraform/
├── modules/              # 共享模块
│   ├── api-gateway/      # HTTP API + Cognito Authorizer
│   ├── lambda-greet/     # Lambda 1: /greet 处理
│   ├── lambda-dispatch/  # Lambda 2: /dispatch 处理
│   ├── dynamodb/         # GreetingLogs 表
│   ├── ecs-fargate/      # ECS Cluster + Task Definition
│   └── cognito/          # Cognito User Pool + Client
│
├── us-east-1/
│   ├── main.tf          # 主配置，调用所有模块
│   ├── backend.tf       # S3 backend: key = "us-east-1/terraform.tfstate"
│   ├── providers.tf     # provider "aws" { region = "us-east-1" }
│   ├── cognito.tf       # Cognito 模块调用
│   ├── greet.tf         # /greet 相关模块调用
│   ├── dispatch.tf      # /dispatch 相关模块调用
│   ├── api-gateway.tf   # API Gateway 模块调用
│   ├── outputs.tf       # 输出配置（包含 Cognito）
│   └── terraform.tfvars # 变量值
│
└── eu-west-1/
    ├── main.tf          # 主配置，调用所有模块
    ├── backend.tf       # S3 backend: key = "eu-west-1/terraform.tfstate"
    ├── providers.tf     # provider "aws" { region = "eu-west-1" }
    ├── greet.tf         # /greet 相关模块调用
    ├── dispatch.tf      # /dispatch 相关模块调用
    ├── api-gateway.tf   # API Gateway 模块调用
    ├── outputs.tf       # 输出配置
    └── terraform.tfvars # 变量值（含 Cognito 引用）
```

**设计原则：**
- 共享模块避免代码重复
- 按业务（/greet、/dispatch）和组件（api-gateway、cognito）分文件组织
- 每个区域独立文件夹，清晰隔离
- Cognito 只在 us-east-1，eu-west-1 通过 tfvars 引用

---

## 4. 数据流

### 4.1 /greet 流程

```
[Client] --JWT--> [API Gateway] --> [Lambda Greet]
                                              │
                                              ├─→ [DynamoDB] 写入日志
                                              │
                                              └─→ [SNS] 发送验证消息
```

### 4.2 /dispatch 流程

```
[Client] --JWT--> [API Gateway] --> [Lambda Dispatch]
                                              │
                                              └─→ [ECS] 启动 Fargate 任务
                                                    │
                                                    └─→ [Container] 发送 SNS 消息
```

---

## 5. 部署策略

### 5.1 State 管理

```
S3 Bucket: unleash-assessment-terraform-state
│
├── us-east-1/terraform.tfstate   → 包含 Cognito + 所有区域资源
└── eu-west-1/terraform.tfstate   → 仅包含区域资源
```

### 5.2 部署步骤

```bash
# 1. 创建 S3 State Bucket
aws s3api create-bucket \
  --bucket unleash-assessment-terraform-state \
  --region us-east-1

# 2. 部署 us-east-1（包含 Cognito）
cd us-east-1
terraform init
terraform apply

# 3. 复制 Cognito 配置到 eu-west-1
# 手动将 outputs 中的值填入 eu-west-1/terraform.tfvars

# 4. 部署 eu-west-1
cd ../eu-west-1
terraform init
terraform apply
```

### 5.3 销毁步骤

```bash
# 先销毁 eu-west-1
cd eu-west-1
terraform destroy

# 再销毁 us-east-1
cd ../us-east-1
terraform destroy
```

---

## 6. 组件清单

| 组件 | 类型 | 区域 | 职责 |
|------|------|------|------|
| **Cognito User Pool** | Auth | us-east-1 | 身份验证、JWT 签发 |
| **API Gateway** | Gateway | us-east-1, eu-west-1 | HTTP API 路由、Cognito Authorizer |
| **Lambda Greet** | Compute | us-east-1, eu-west-1 | /greet 处理、写 DDB、发 SNS |
| **Lambda Dispatch** | Compute | us-east-1, eu-west-1 | /dispatch 处理、触发 ECS |
| **ECS Fargate** | Container | us-east-1, eu-west-1 | 运行容器、发 SNS |
| **DynamoDB** | Database | us-east-1, eu-west-1 | 存储 GreetingLogs |
| **SNS Topic** | Messaging | us-east-1 | 接收验证消息 |

---

## 7. 架构决策记录 (ADR)

| ADR | 决策 | 理由 |
|-----|------|------|
| **ADR-001** | 使用两个文件夹实现多区域部署 | 清晰隔离，易于管理，按业务分文件 |
| **ADR-002** | 使用 S3 作为 State Backend（无锁） | 简单直接，单人开发无需锁 |
| **ADR-003** | Cognito 集中部署在 us-east-1 | PDF 要求，手动传递配置 |
| **ADR-004** | ECS Fargate 使用公共子网 | PDF 要求，避免 NAT Gateway 费用 |

### ADR-001: 两个文件夹方案

**决策：** 每个区域独立的文件夹，共享 modules/ 目录

**理由：**
- 清晰隔离，易于管理
- 按业务（/greet、/dispatch）分文件组织
- 使用共享模块避免代码重复
- Cognito 只在 us-east-1 文件夹中

**后果：**
- 需要手动传递 Cognito 配置
- 两次独立的 terraform apply

### ADR-002: S3 State Backend（无锁）

**决策：** 使用 S3 存储 state，不使用 DynamoDB 锁

**理由：**
- 单人开发，无需状态锁
- 简单直接，降低复杂度
- 手动控制并发，同时只操作一个区域

### ADR-003: Cognito 集中部署

**决策：** Cognito 集中在 us-east-1，eu-west-1 跨区域引用

**理由：**
- PDF 明确要求
- 延迟测试是评估目的之一，无需优化
- 手动传递配置最简单

### ADR-004: ECS 公共子网

**决策：** Fargate 任务部署到公共子网

**理由：**
- PDF 明确要求避免 NAT Gateway 费用
- Security Group 限制出站流量，只允许 SNS
- 容器无需暴露端口，安全可控

---

## 8. 外部依赖

| 依赖 | 说明 | 必需 |
|------|------|------|
| **AWS Cognito** | 身份验证 | ✅ |
| **AWS Lambda** | 计算平台 | ✅ |
| **AWS ECS Fargate** | 容器平台 | ✅ |
| **AWS DynamoDB** | 数据库 | ✅ |
| **AWS SNS** | 消息队列 | ✅ |
| **GitHub** | 代码托管 | ✅ |
| **Terraform** | IaC 工具 | ✅ |

---

## 9. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| **成本超支** | 中 | 公共子网避免 NAT，完成后立即 destroy |
| **跨区域 SNS** | 低 | IAM Role 包含跨区域 SNS 发布权限 |
| **ECS 启动慢** | 低 | 使用官方 aws-cli 镜像，按需启动 |

---

*文档版本: 2.0*
*创建日期: 2026-03-02*
*最后更新: 2026-03-02*
