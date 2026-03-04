# Phase 2: 共享模块开发

**预计时间：** 50分钟
**负责 Agent：** IaC Agent
**依赖：** Phase 1 完成
**状态：** ✅ 已完成

---

## 阶段目标

开发 5 个 Terraform 共享模块，用于两个区域的部署。

> **注意：** Cognito 不作为共享模块，将在 Phase 3 (us-east-1) 中直接配置。

---

## 模块清单

| 模块 | 文件 | 说明 |
|------|------|------|
| **dynamodb** | modules/dynamodb/ | GreetingLogs 表 |
| **lambda-greet** | modules/lambda-greet/ | /greet 处理函数 |
| **lambda-dispatch** | modules/lambda-dispatch/ | /dispatch 处理函数 |
| **api-gateway** | modules/api-gateway/ | HTTP API + 路由 |
| **ecs-fargate** | modules/ecs-fargate/ | ECS Cluster + Task Definition |

---

## 任务清单

### IAC-001: DynamoDB 模块

| 字段 | 内容 |
|------|------|
| **Task ID** | `IAC-001` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | 创建 GreetingLogs 表模块，按需计费 |
| **Deliverable** | `modules/dynamodb/{main.tf,variables.tf,outputs.tf}` |
| **Acceptance Criteria** | fmt/validate 通过 |

### IAC-002: Lambda Greet 模块

| 字段 | 内容 |
|------|------|
| **Task ID** | `IAC-002` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | 创建 /greet Lambda 函数（Python 3.11） |
| **Deliverable** | `modules/lambda-greet/{main.tf,variables.tf,outputs.tf,lambda.py}` |
| **Acceptance Criteria** | Lambda 代码能写 DDB + 发 SNS |

### IAC-003: Lambda Dispatch 模块

| 字段 | 内容 |
|------|------|
| **Task ID** | `IAC-003` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | 创建 /dispatch Lambda 函数（触发 ECS） |
| **Deliverable** | `modules/lambda-dispatch/{main.tf,variables.tf,outputs.tf,lambda.py}` |
| **Acceptance Criteria** | Lambda 代码能调用 ECS RunTask |

### IAC-004: API Gateway 模块

| 字段 | 内容 |
|------|------|
| **Task ID** | `IAC-004` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `IAC-002`, `IAC-003` |
| **Description** | 创建 HTTP API + /greet 和 /dispatch 路由 + Cognito Authorizer |
| **Deliverable** | `modules/api-gateway/{main.tf,variables.tf,outputs.tf}` |
| **Acceptance Criteria** | API Gateway 配置两个路由 |

### IAC-005: ECS Fargate 模块

| 字段 | 内容 |
|------|------|
| **Task ID** | `IAC-005` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | 创建 ECS Cluster + Task Definition（公共子网） |
| **Deliverable** | `modules/ecs-fargate/{main.tf,variables.tf,outputs.tf,userdata.sh}` |
| **Acceptance Criteria** | 使用 amazon/aws-cli 镜像、公共子网部署 |

---

## 执行顺序

```
IAC-001 ✅ ──┐
IAC-002 ✅ ──┼─→ IAC-004 ✅ ──┐
IAC-003 ✅ ──┤                ├──→ 完成
             │                │
IAC-005 ✅ ───┴────────────────┘
```

---

## 验收标准

- [x] 所有模块 `terraform fmt/validate` 通过
- [x] 模块包含必需的元数据
- [x] Lambda 代码逻辑正确

---

## 交付物

| 模块 | 文件 |
|------|------|
| dynamodb | main.tf, variables.tf, outputs.tf |
| lambda-greet | main.tf, variables.tf, outputs.tf, lambda.py |
| lambda-dispatch | main.tf, variables.tf, outputs.tf, lambda.py |
| api-gateway | main.tf, variables.tf, outputs.tf |
| ecs-fargate | main.tf, variables.tf, outputs.tf, userdata.sh |

---

## 下一阶段

✅ **已完成** → 进入 **[Phase 3: us-east-1 部署](../03-useast1/plan.md)**
