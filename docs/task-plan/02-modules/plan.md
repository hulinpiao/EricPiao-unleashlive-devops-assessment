# Phase 2: Shared Module Development

**Estimated Time:** 50 minutes
**Responsible Agent:** IaC Agent
**Dependencies:** Phase 1 complete
**Status:** ✅ Complete

---

## Phase Objective

Develop 5 Terraform shared modules for deployment in both regions.

> **Note:** Cognito is not a shared module and will be configured directly in Phase 3 (us-east-1).

---

## Module List

| Module | Files | Description |
|--------|-------|-------------|
| **dynamodb** | modules/dynamodb/ | GreetingLogs table |
| **lambda-greet** | modules/lambda-greet/ | /greet handler function |
| **lambda-dispatch** | modules/lambda-dispatch/ | /dispatch handler function |
| **api-gateway** | modules/api-gateway/ | HTTP API + routes |
| **ecs-fargate** | modules/ecs-fargate/ | ECS Cluster + Task Definition |

---

## Task List

### IAC-001: DynamoDB Module

| Field | Content |
|-------|---------|
| **Task ID** | `IAC-001` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | Create GreetingLogs table module with on-demand billing |
| **Deliverable** | `modules/dynamodb/{main.tf,variables.tf,outputs.tf}` |
| **Acceptance Criteria** | fmt/validate passes |

### IAC-002: Lambda Greet Module

| Field | Content |
|-------|---------|
| **Task ID** | `IAC-002` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | Create /greet Lambda function (Python 3.11) |
| **Deliverable** | `modules/lambda-greet/{main.tf,variables.tf,outputs.tf,lambda.py}` |
| **Acceptance Criteria** | Lambda code can write to DDB + send SNS |

### IAC-003: Lambda Dispatch Module

| Field | Content |
|-------|---------|
| **Task ID** | `IAC-003` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | Create /dispatch Lambda function (triggers ECS) |
| **Deliverable** | `modules/lambda-dispatch/{main.tf,variables.tf,outputs.tf,lambda.py}` |
| **Acceptance Criteria** | Lambda code can invoke ECS RunTask |

### IAC-004: API Gateway Module

| Field | Content |
|-------|---------|
| **Task ID** | `IAC-004` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `IAC-002`, `IAC-003` |
| **Description** | Create HTTP API + /greet and /dispatch routes + Cognito Authorizer |
| **Deliverable** | `modules/api-gateway/{main.tf,variables.tf,outputs.tf}` |
| **Acceptance Criteria** | API Gateway configured with two routes |

### IAC-005: ECS Fargate Module

| Field | Content |
|-------|---------|
| **Task ID** | `IAC-005` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | Create ECS Cluster + Task Definition (public subnet) |
| **Deliverable** | `modules/ecs-fargate/{main.tf,variables.tf,outputs.tf,userdata.sh}` |
| **Acceptance Criteria** | Uses amazon/aws-cli image, deployed in public subnet |

---

## Execution Order

```
IAC-001 ✅ ──┐
IAC-002 ✅ ──┼─→ IAC-004 ✅ ──┐
IAC-003 ✅ ──┤                ├──→ Complete
             │                │
IAC-005 ✅ ───┴────────────────┘
```

---

## Acceptance Criteria

- [x] All modules pass `terraform fmt/validate`
- [x] Modules include required metadata
- [x] Lambda code logic is correct

---

## Deliverables

| Module | Files |
|--------|-------|
| dynamodb | main.tf, variables.tf, outputs.tf |
| lambda-greet | main.tf, variables.tf, outputs.tf, lambda.py |
| lambda-dispatch | main.tf, variables.tf, outputs.tf, lambda.py |
| api-gateway | main.tf, variables.tf, outputs.tf |
| ecs-fargate | main.tf, variables.tf, outputs.tf, userdata.sh |

---

## Next Phase

✅ **Complete** → Proceed to **[Phase 3: us-east-1 Deployment](../03-useast1/plan.md)**
