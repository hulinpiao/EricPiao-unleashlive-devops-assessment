# Phase 3: us-east-1 Deployment

**Estimated Time:** 30 minutes
**Responsible Agent:** IaC Agent (code), Team Lead (execution)
**Dependencies:** Phase 2 complete
**Status:** ✅ Complete

---

## Phase Objective

Deploy complete infrastructure in us-east-1 region (including Cognito).

---

## Task List

### DEP-001: Main Configuration Files

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-001` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Description** | Create us-east-1 main configuration, backend, providers |
| **Deliverable** | `us-east-1/{main.tf,backend.tf,providers.tf,terraform.tfvars,variables.tf}` |
| **Acceptance Criteria** | `terraform init` succeeds |

### DEP-002: Cognito Configuration

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-002` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001` |
| **Description** | Configure Cognito User Pool and Client directly (not using module) |
| **Deliverable** | `us-east-1/cognito.tf` |
| **Acceptance Criteria** | Cognito configured correctly, User Pool and Client created successfully |
| **Actual Output** | Pool ID: `us-east-1_l3E5QLXQS`, Client ID: `3qkmqvl0dchmmubm99td0s39fq` |

### DEP-003: /greet Business Configuration

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-003` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001`, `DEP-002` |
| **Description** | Configure /greet endpoint (API Gateway + Lambda + DynamoDB + SNS) |
| **Deliverable** | `us-east-1/greet.tf` |
| **Acceptance Criteria** | Endpoint configured correctly |
| **Actual Output** | Lambda: `aws-devops-assessment-greet`, Table: `GreetingLogs` |

### DEP-004: /dispatch Business Configuration

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-004` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001`, `DEP-002` |
| **Description** | Configure /dispatch endpoint (API Gateway + Lambda + ECS + SNS) |
| **Deliverable** | `us-east-1/dispatch.tf` |
| **Acceptance Criteria** | Endpoint configured correctly |
| **Actual Output** | Lambda: `aws-devops-assessment-dispatch`, ECS: `aws-devops-assessment-ecs` |

### DEP-005: Outputs Configuration

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-005` |
| **Status** | ✅ Complete |
| **Owner** | IaC Agent |
| **Skill** | `/terraform-engineer` |
| **Depends On** | `DEP-001`, `DEP-002`, `DEP-003`, `DEP-004` |
| **Description** | Output Cognito configuration and API Gateway URL |
| **Deliverable** | `us-east-1/outputs.tf` |
| **Acceptance Criteria** | All required outputs defined |

### DEP-006: Execute Deployment

| Field | Content |
|-------|---------|
| **Task ID** | `DEP-006` |
| **Status** | ✅ Complete |
| **Owner** | Team Lead |
| **Depends On** | `DEP-001`, `DEP-002`, `DEP-003`, `DEP-004`, `DEP-005` |
| **Description** | Execute `terraform init` and `terraform apply` |
| **Deliverable** | All us-east-1 resources deployed successfully |
| **Acceptance Criteria** | Resources created successfully, can retrieve Cognito configuration |
| **Deployment Date** | 2026-03-04 |
| **API URL** | `https://m0jtt2ga9b.execute-api.us-east-1.amazonaws.com/$default` |

---

## Execution Order

```
DEP-001 (Main Config) ✅
    │
    ├──→ DEP-002 (Cognito) ✅ ──┐
    │                          │
    ├──→ DEP-003 (greet) ✅ ────┤
    │                          ├──→ DEP-005 (outputs) ✅
    └──→ DEP-004 (dispatch) ✅ ─┤
                               │
                               ├──→ DEP-006 (Deployment) ✅
```

---

## Acceptance Criteria

- [x] `terraform apply` without errors
- [x] Resources created successfully
- [x] Cognito User Pool and Client available
- [x] API Gateway URL accessible
- [x] Can retrieve Cognito configuration (outputs)
- [x] AWS infrastructure matches Terraform code exactly

---

## Deployment Output

### Cognito Configuration
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

## Issues Encountered and Solutions

### Issue 1: Cognito JWT Issuer URL Format Error
- **Error**: `Invalid issuer: Issuer is not a valid URL for JWT Authorizer`
- **Cause**: Used Cognito Domain instead of User Pool Issuer URL
- **Solution**: Changed to `https://cognito-idp.{region}.amazonaws.com/{pool_id}`

### Issue 2: API Gateway Route Target Format Error
- **Error**: `expected length of target to be in the range (1 - 128)`
- **Cause**: Route target used Lambda ARN instead of Integration ID
- **Solution**: Changed to `target = "integrations/${integration.id}"`

### Issue 3: Integration Missing integration_uri
- **Cause**: API Gateway v2 Integration requires explicit Lambda URI
- **Solution**: Added `integration_uri = lambda_function_arn`

---

## Next Phase

✅ **Complete** → Proceed to **[Phase 4: eu-west-1 Deployment](../04-euwest1/plan.md)**

**Phase 4 will use:**
- Cognito Pool ID: `us-east-1_l3E5QLXQS`
- Cognito Client ID: `3qkmqvl0dchmmubm99td0s39fq`
