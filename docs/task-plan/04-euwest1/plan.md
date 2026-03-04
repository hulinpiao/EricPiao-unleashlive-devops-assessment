# Phase 4: eu-west-1 Deployment

**Estimated Time:** 20 minutes
**Responsible Agent:** IaC Agent (code), Team Lead (execution)
**Dependencies:** Phase 3 complete
**Status:** ✅ Complete

---

## Phase Objective

Deploy infrastructure in eu-west-1 region (referencing us-east-1 Cognito).

---

## Task List

### DEP-007: Main Configuration Files

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-007` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-006` (Phase 3) |
| **Description** | Create eu-west-1 main configuration, backend, providers |
| **Deliverable** | `eu-west-1/{main.tf,backend.tf,providers.tf,terraform.tfvars,variables.tf}` |
| **Acceptance Criteria** | `terraform init` succeeds, Cognito configuration passed in |

### DEP-008: /greet Business Configuration

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-008` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-007` |
| **Description** | Configure /greet endpoint (referencing us-east-1 Cognito) |
| **Deliverable** | `eu-west-1/greet.tf` |
| **Acceptance Criteria** | Endpoint configured correctly, Cognito Authorizer references us-east-1 |
| **Actual Output** | Lambda: `aws-devops-assessment-greet-eu`, Table: `GreetingLogs` |

### DEP-009: /dispatch Business Configuration

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-009` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-007` |
| **Description** | Configure /dispatch endpoint (referencing us-east-1 Cognito) |
| **Deliverable** | `eu-west-1/dispatch.tf` |
| **Acceptance Criteria** | Endpoint configured correctly, Cognito Authorizer references us-east-1 |
| **Actual Output** | Lambda: `aws-devops-assessment-dispatch-eu`, ECS: `aws-devops-assessment-ecs-eu` |

### DEP-010: Execute Deployment

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-010` |
| **Status** | ✅ Complete |
| **Owner** | Team Lead |
| **Depends On** | `DEP-007`, `DEP-008`, `DEP-009` |
| **Description** | Execute `terraform init` and `terraform apply` |
| **Deliverable** | All eu-west-1 resources deployed successfully |
| **Acceptance Criteria** | Resources created successfully, eu-west-1 API accessible |
| **Deployment Date** | 2026-03-04 |
| **API URL** | `https://riqs64byr7.execute-api.eu-west-1.amazonaws.com/$default` |

---

## Execution Order

```
DEP-007 ✅ (Main Config, includes Cognito reference)
    │
    ├──→ DEP-008 ✅ (greet) ──┐
    │                        │
    └──→ DEP-009 ✅ (dispatch)├──→ DEP-010 ✅ (Deployment)
                            │
```

---

## Acceptance Criteria

- [x] `terraform apply` without errors
- [x] Resources created successfully
- [x] eu-west-1 API accessible
- [x] Both regional /greet and /dispatch endpoints working correctly
- [x] AWS infrastructure matches Terraform code exactly

---

## Deployment Output

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

### Cross-Region Configuration
```
Cognito:    Uses us-east-1 User Pool (us-east-1_l3E5QLXQS)
SNS Topic:  Uses us-east-1 SNS Topic
```

---

## Issues Encountered and Solutions

### Issue: IAM Role Name Conflict
- **Error**: `EntityAlreadyExists: Role with name aws-devops-assessment-dispatch-task-execution-role already exists`
- **Cause**: us-east-1 and eu-west-1 used the same resource names
- **Solution**: Added `-eu` suffix to eu-west-1 resources

**Modified Resource Names:**
- `aws-devops-assessment-greet` → `aws-devops-assessment-greet-eu`
- `aws-devops-assessment-dispatch` → `aws-devops-assessment-dispatch-eu`
- `aws-devops-assessment-ecs` → `aws-devops-assessment-ecs-eu`
- `aws-devops-assessment-api` → `aws-devops-assessment-api-eu`

---

## Next Phase

✅ **Complete** → Proceed to **[Phase 5: Test Development](../05-test/plan.md)** or **[Phase 7: Documentation](../07-docs/plan.md)**
