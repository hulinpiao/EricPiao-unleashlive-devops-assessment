# AWS DevOps Assessment - Solution Architecture

---

## 1. High-Level User Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                      User Operation Workflow                     │
└─────────────────────────────────────────────────────────────────┘

  Candidate                       Recruitment Team
     │                                │
     │ 1. Deploy infrastructure       │
     │    - us-east-1 (incl. Cognito) │
     │    - eu-west-1                 │
     │                                │
     │ 2. Run test script             │
     │    - Cognito login             │
     │    - Concurrent calls to 4 APIs│
     │                                │
     │ 3. Trigger verification ───────► 4. Receive 4 SNS messages
     │    - Lambda → SNS (2 messages)   - Verify candidate info
     │    - ECS → SNS (2 messages)      - Technical review
     │                                    │
     │                                │ 5. Send interview invitation
     │ 6. Destroy infrastructure ◄───────────
     │    - terraform destroy
```

**Key Path:** Login → Concurrent calls to 4 endpoints → Send 4 SNS messages → Verification

---

## 2. System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         Overall Architecture                      │
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

## 3. Project Structure

```
terraform/
├── modules/              # Shared modules
│   ├── api-gateway/      # HTTP API + Cognito Authorizer
│   ├── lambda-greet/     # Lambda 1: /greet handler
│   ├── lambda-dispatch/  # Lambda 2: /dispatch handler
│   ├── dynamodb/         # GreetingLogs table
│   ├── ecs-fargate/      # ECS Cluster + Task Definition
│   └── cognito/          # Cognito User Pool + Client
│
├── us-east-1/
│   ├── main.tf          # Main configuration, calls all modules
│   ├── backend.tf       # S3 backend: key = "us-east-1/terraform.tfstate"
│   ├── providers.tf     # provider "aws" { region = "us-east-1" }
│   ├── cognito.tf       # Cognito module invocation
│   ├── greet.tf         # /greet related module invocations
│   ├── dispatch.tf      # /dispatch related module invocations
│   ├── api-gateway.tf   # API Gateway module invocation
│   ├── outputs.tf       # Output configuration (includes Cognito)
│   └── terraform.tfvars # Variable values
│
└── eu-west-1/
    ├── main.tf          # Main configuration, calls all modules
    ├── backend.tf       # S3 backend: key = "eu-west-1/terraform.tfstate"
    ├── providers.tf     # provider "aws" { region = "eu-west-1" }
    ├── greet.tf         # /greet related module invocations
    ├── dispatch.tf      # /dispatch related module invocations
    ├── api-gateway.tf   # API Gateway module invocation
    ├── outputs.tf       # Output configuration
    └── terraform.tfvars # Variable values (includes Cognito reference)
```

**Design Principles:**
- Shared modules avoid code duplication
- Organized by business (/greet, /dispatch) and component (api-gateway, cognito) in separate files
- Each region has independent folder for clear isolation
- Cognito only in us-east-1, eu-west-1 references via tfvars

---

## 4. Data Flow

### 4.1 /greet Flow

```
[Client] --JWT--> [API Gateway] --> [Lambda Greet]
                                              │
                                              ├─→ [DynamoDB] Write log
                                              │
                                              └─→ [SNS] Send verification message
```

### 4.2 /dispatch Flow

```
[Client] --JWT--> [API Gateway] --> [Lambda Dispatch]
                                              │
                                              └─→ [ECS] Start Fargate task
                                                    │
                                                    └─→ [Container] Send SNS message
```

---

## 5. Deployment Strategy

### 5.1 State Management

```
S3 Bucket: unleash-assessment-terraform-state
│
├── us-east-1/terraform.tfstate   → Contains Cognito + all regional resources
└── eu-west-1/terraform.tfstate   → Contains only regional resources
```

### 5.2 Deployment Steps

```bash
# 1. Create S3 State Bucket
aws s3api create-bucket \
  --bucket unleash-assessment-terraform-state \
  --region us-east-1

# 2. Deploy us-east-1 (includes Cognito)
cd us-east-1
terraform init
terraform apply

# 3. Copy Cognito configuration to eu-west-1
# Manually fill values from outputs into eu-west-1/terraform.tfvars

# 4. Deploy eu-west-1
cd ../eu-west-1
terraform init
terraform apply
```

### 5.3 Destruction Steps

```bash
# First destroy eu-west-1
cd eu-west-1
terraform destroy

# Then destroy us-east-1
cd ../us-east-1
terraform destroy
```

---

## 6. Component Inventory

| Component | Type | Region | Responsibility |
|-----------|------|--------|----------------|
| **Cognito User Pool** | Auth | us-east-1 | Authentication, JWT issuance |
| **API Gateway** | Gateway | us-east-1, eu-west-1 | HTTP API routing, Cognito Authorizer |
| **Lambda Greet** | Compute | us-east-1, eu-west-1 | /greet handler, write DDB, send SNS |
| **Lambda Dispatch** | Compute | us-east-1, eu-west-1 | /dispatch handler, trigger ECS |
| **ECS Fargate** | Container | us-east-1, eu-west-1 | Run container, send SNS |
| **DynamoDB** | Database | us-east-1, eu-west-1 | Store GreetingLogs |
| **SNS Topic** | Messaging | us-east-1 | Receive verification messages |

---

## 7. Architecture Decision Records (ADR)

| ADR | Decision | Rationale |
|-----|----------|-----------|
| **ADR-001** | Use two folders for multi-region deployment | Clear isolation, easy management, organized by business in files |
| **ADR-002** | Use S3 as State Backend (no lock) | Simple and direct, single developer doesn't need locking |
| **ADR-003** | Cognito centrally deployed in us-east-1 | PDF requirement, manual configuration passing |
| **ADR-004** | ECS Fargate uses public subnet | PDF requirement, avoid NAT Gateway costs |

### ADR-001: Two Folder Approach

**Decision:** Each region has independent folder, sharing modules/ directory

**Rationale:**
- Clear isolation, easy management
- Organized by business (/greet, /dispatch) in separate files
- Use shared modules to avoid code duplication
- Cognito only in us-east-1 folder

**Consequences:**
- Need to manually pass Cognito configuration
- Two separate terraform apply executions

### ADR-002: S3 State Backend (No Lock)

**Decision:** Use S3 to store state, no DynamoDB lock

**Rationale:**
- Single developer, no state locking needed
- Simple and direct, reduced complexity
- Manual concurrency control, operate one region at a time

### ADR-003: Centralized Cognito Deployment

**Decision:** Cognito centralized in us-east-1, eu-west-1 cross-region reference

**Rationale:**
- PDF explicitly requires this
- Latency testing is part of assessment purpose, no optimization needed
- Manual configuration passing is simplest

### ADR-004: ECS Public Subnet

**Decision:** Fargate tasks deployed to public subnet

**Rationale:**
- PDF explicitly requires avoiding NAT Gateway costs
- Security Group limits outbound traffic, only allow SNS
- Container doesn't need exposed ports, secure and controllable

---

## 8. External Dependencies

| Dependency | Description | Required |
|------------|-------------|----------|
| **AWS Cognito** | Authentication | ✅ |
| **AWS Lambda** | Compute platform | ✅ |
| **AWS ECS Fargate** | Container platform | ✅ |
| **AWS DynamoDB** | Database | ✅ |
| **AWS SNS** | Message queue | ✅ |
| **GitHub** | Code hosting | ✅ |
| **Terraform** | IaC tool | ✅ |

---

## 9. Risks and Mitigation

| Risk | Impact | Mitigation Measures |
|------|--------|---------------------|
| **Cost overrun** | Medium | Use public subnet to avoid NAT, destroy immediately after completion |
| **Cross-region SNS** | Low | IAM Role includes cross-region SNS publish permission |
| **ECS slow startup** | Low | Use official aws-cli image, start on demand |

---

*Document Version: 2.0*
*Created: 2026-03-02*
*Last Updated: 2026-03-02*
