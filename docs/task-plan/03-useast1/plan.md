# Phase 3: us-east-1 部署

**预计时间：** 30分钟
**负责 Agent：** IaC Agent（代码）、Team Lead（执行）
**依赖：** Phase 2 完成
**状态：** ✅ 已完成

---

## 阶段目标

在 us-east-1 区域部署完整基础设施（包含 Cognito）。

---

## 任务清单

### DEP-001: 主配置文件

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-001` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | 创建 us-east-1 主配置、backend、providers |
| **Deliverable** | `us-east-1/{main.tf,backend.tf,providers.tf,terraform.tfvars,variables.tf}` |
| **Acceptance Criteria** | `terraform init` 成功 |

### DEP-002: Cognito 配置

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-002` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001` |
| **Description** | 直接配置 Cognito User Pool 和 Client（不使用模块） |
| **Deliverable** | `us-east-1/cognito.tf` |
| **Acceptance Criteria** | Cognito 配置正确、User Pool 和 Client 创建成功 |
| **实际输出** | Pool ID: `us-east-1_l3E5QLXQS`, Client ID: `3qkmqvl0dchmmubm99td0s39fq` |

### DEP-003: /greet 业务配置

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-003` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001`, `DEP-002` |
| **Description** | 配置 /greet 端点（API Gateway + Lambda + DynamoDB + SNS） |
| **Deliverable** | `us-east-1/greet.tf` |
| **Acceptance Criteria** | 端点配置正确 |
| **实际输出** | Lambda: `aws-devops-assessment-greet`, Table: `GreetingLogs` |

### DEP-004: /dispatch 业务配置

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-004` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001`, `DEP-002` |
| **Description** | 配置 /dispatch 端点（API Gateway + Lambda + ECS + SNS） |
| **Deliverable** | `us-east-1/dispatch.tf` |
| **Acceptance Criteria** | 端点配置正确 |
| **实际输出** | Lambda: `aws-devops-assessment-dispatch`, ECS: `aws-devops-assessment-ecs` |

### DEP-005: Outputs 配置

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-005` |
| **Status** | ✅ 完成 |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001`, `DEP-002`, `DEP-003`, `DEP-004` |
| **Description** | 输出 Cognito 配置和 API Gateway URL |
| **Deliverable** | `us-east-1/outputs.tf` |
| **Acceptance Criteria** | 所有必需输出已定义 |

### DEP-006: 执行部署

| 字段 | 内容 |
|------|------|
| **Task ID** | `DEP-006` |
| **Status** | ✅ 完成 |
| **Owner** | Team Lead |
| **Depends On** | `DEP-001`, `DEP-002`, `DEP-003`, `DEP-004`, `DEP-005` |
| **Description** | 执行 `terraform init` 和 `terraform apply` |
| **Deliverable** | us-east-1 所有资源部署成功 |
| **Acceptance Criteria** | 资源创建成功、可获取 Cognito 配置 |
| **部署时间** | 2026-03-04 |
| **API URL** | `https://m0jtt2ga9b.execute-api.us-east-1.amazonaws.com/$default` |

---

## 执行顺序

```
DEP-001 (主配置) ✅
    │
    ├──→ DEP-002 (Cognito) ✅ ──┐
    │                        │
    ├──→ DEP-003 (greet) ✅ ───┤
    │                        ├──→ DEP-005 (outputs) ✅
    └──→ DEP-004 (dispatch) ✅ ─┤
                             │
                             ├──→ DEP-006 (部署) ✅
```

---

## 验收标准

- [x] `terraform apply` 无错误
- [x] 资源创建成功
- [x] Cognito User Pool 和 Client 可用
- [x] API Gateway URL 可访问
- [x] 可以获取 Cognito 配置（outputs）
- [x] AWS 基础设施与 Terraform 代码完全对应

---

## 部署输出

### Cognito 配置
```
User Pool ID:  us-east-1_l3E5QLXQS
User Pool ARN: arn:aws:cognito-idp:us-east-1:160676960050:userpool/us-east-1_l3E5QLXQS
Client ID:      3qkmqvl0dchmmubm99td0s39fq
Issuer URL:     https://cognito-idp.us-east-1.amazonaws.com/us-east-1_l3E5QLXQS
```

### API Gateway
```
API Endpoint:   https://m0jtt2ga9b.execute-api.us-east-1.amazonaws.com
Invoke URL:     https://m0jtt2ga9b.execute-api.us-east-1.amazonaws.com/$default
/greet URL:     https://m0jtt2ga9b.execute-api.us-east-1.amazonaws.com/$default/
/dispatch URL:  https://m0jtt2ga9b.execute-api.us-east-1.amazonaws.com/$default/dispatch
```

### Lambda Functions
```
Greet:     aws-devops-assessment-greet (python3.11, 256MB, 30s)
Dispatch:  aws-devops-assessment-dispatch (python3.11, 256MB, 30s)
```

### DynamoDB
```
Table:  GreetingLogs
Key:    PK (String)
Mode:   PAY_PER_REQUEST
```

### ECS Fargate
```
Cluster:        aws-devops-assessment-ecs
Task Def:       aws-devops-assessment-dispatch-task:1
Network Mode:   awsvpc
Launch Type:    FARGATE
```

---

## 遇到的问题及解决方案

### 问题 1: Cognito JWT Issuer URL 格式错误
- **错误**: `Invalid issuer: Issuer is not a valid URL for JWT Authorizer`
- **原因**: 使用了 Cognito Domain 而非 User Pool Issuer URL
- **解决**: 改为 `https://cognito-idp.{region}.amazonaws.com/{pool_id}`

### 问题 2: API Gateway Route Target 格式错误
- **错误**: `expected length of target to be in the range (1 - 128)`
- **原因**: Route target 使用了 Lambda ARN 而非 Integration ID
- **解决**: 改为 `target = "integrations/${integration.id}"`

### 问题 3: Integration 缺少 integration_uri
- **原因**: API Gateway v2 Integration 需要明确指定 Lambda URI
- **解决**: 添加 `integration_uri = lambda_function_arn`

---

## 下一阶段

✅ **已完成** → 进入 **[Phase 4: eu-west-1 部署](../04-euwest1/plan.md)**

**Phase 4 将使用:**
- Cognito Pool ID: `us-east-1_l3E5QLXQS`
- Cognito Client ID: `3qkmqvl0dchmmubm99td0s39fq`
