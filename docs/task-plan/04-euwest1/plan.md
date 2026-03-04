# Phase 4: eu-west-1 部署

**预计时间：** 20分钟
**负责 Agent：** IaC Agent（代码）、Team Lead（执行）
**依赖：** Phase 3 完成
**状态：** ✅ 已完成

---

## 阶段目标

在 eu-west-1 区域部署基础设施（引用 us-east-1 的 Cognito）。

---

## 任务清单

### DEP-007: 主配置文件

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-007` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-006` (Phase 3) |
| **Description** | 创建 eu-west-1 主配置、backend、providers |
| **Deliverable** | `eu-west-1/{main.tf,backend.tf,providers.tf,terraform.tfvars,variables.tf}` |
| **Acceptance Criteria** | `terraform init` 成功、Cognito 配置已传入 |

### DEP-008: /greet 业务配置

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-008` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-007` |
| **Description** | 配置 /greet 端点（引用 us-east-1 的 Cognito） |
| **Deliverable** | `eu-west-1/greet.tf` |
| **Acceptance Criteria** | 端点配置正确、Cognito Authorizer 引用 us-east-1 |
| **实际输出** | Lambda: `aws-devops-assessment-greet-eu`, Table: `GreetingLogs` |

### DEP-009: /dispatch 业务配置

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-009` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-007` |
| **Description** | 配置 /dispatch 端点（引用 us-east-1 的 Cognito） |
| **Deliverable** | `eu-west-1/dispatch.tf` |
| **Acceptance Criteria** | 端点配置正确、Cognito Authorizer 引用 us-east-1 |
| **实际输出** | Lambda: `aws-devops-assessment-dispatch-eu`, ECS: `aws-devops-assessment-ecs-eu` |

### DEP-010: 执行部署

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-010` |
| **Status** | ✅ 完成 |
| **Owner** | Team Lead |
| **Depends On** | `DEP-007`, `DEP-008`, `DEP-009` |
| **Description** | 执行 `terraform init` 和 `terraform apply` |
| **Deliverable** | eu-west-1 所有资源部署成功 |
| **Acceptance Criteria** | 资源创建成功、eu-west-1 API 可访问 |
| **部署时间** | 2026-03-04 |
| **API URL** | `https://riqs64byr7.execute-api.eu-west-1.amazonaws.com/$default` |

---

## 执行顺序

```
DEP-007 ✅ (主配置，含 Cognito 引用)
    │
    ├──→ DEP-008 ✅ (greet) ──┐
    │                       │
    └──→ DEP-009 ✅ (dispatch)├──→ DEP-010 ✅ (部署)
                           │
```

---

## 验收标准

- [x] `terraform apply` 无错误
- [x] 资源创建成功
- [x] eu-west-1 API 可访问
- [x] 两个区域的 /greet 和 /dispatch 端点都正常
- [x] AWS 基础设施与 Terraform 代码完全对应

---

## 部署输出

### API Gateway
```
API Endpoint:   https://riqs64byr7.execute-api.eu-west-1.amazonaws.com
Invoke URL:     https://riqs64byr7.execute-api.eu-west-1.amazonaws.com/$default
/greet URL:     https://riqs64byr7.execute-api.eu-west-1.amazonaws.com/$default/
/dispatch URL:  https://riqs64byr7.execute-api.eu-west-1.amazonaws.com/$default/dispatch
```

### Lambda Functions
```
Greet:     aws-devops-assessment-greet-eu (python3.11, 256MB, 30s)
Dispatch:  aws-devops-assessment-dispatch-eu (python3.11, 256MB, 30s)
```

### ECS Fargate
```
Cluster:        aws-devops-assessment-ecs-eu
Task Def:       aws-devops-assessment-dispatch-task-eu:1
```

### 跨区域配置
```
Cognito:    使用 us-east-1 的 User Pool (us-east-1_l3E5QLXQS)
SNS Topic:   使用 us-east-1 的 SNS Topic
```

---

## 遇到的问题及解决方案

### 问题: IAM 角色名称冲突
- **错误**: `EntityAlreadyExists: Role with name aws-devops-assessment-dispatch-task-execution-role already exists`
- **原因**: us-east-1 和 eu-west-1 使用了相同的资源名称
- **解决**: 为 eu-west-1 的资源添加 `-eu` 后缀

**修改的资源名称：**
- `aws-devops-assessment-greet` → `aws-devops-assessment-greet-eu`
- `aws-devops-assessment-dispatch` → `aws-devops-assessment-dispatch-eu`
- `aws-devops-assessment-ecs` → `aws-devops-assessment-ecs-eu`
- `aws-devops-assessment-api` → `aws-devops-assessment-api-eu`

---

## 下一阶段

✅ **已完成** → 进入 **[Phase 5: 测试开发](../05-test/plan.md)** 或 **[Phase 7: 文档编写](../07-docs/plan.md)**
