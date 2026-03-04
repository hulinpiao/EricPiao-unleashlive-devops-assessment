# AWS DevOps Assessment - PRD
## Product Requirements Document

---

## 1. Project Overview

### 1.1 Project Name
Unleash live - AWS DevOps Engineer Skill Assessment

### 1.2 Project Objectives
Build a multi-region AWS infrastructure to demonstrate the following capabilities:
- IaC (Infrastructure as Code) best practices
- Multi-region deployment architecture design
- Authentication and security configuration
- Cost-optimized container orchestration
- Automated testing and CI/CD

### 1.3 Constraints
- Time limit: 3 hours
- Region requirements: us-east-1 + eu-west-1
- Submission deadline: March 15, 2026
- Resources must be destroyed immediately after completion

---

## 2. Tech Stack

| Component | Technology Choice |
|-----------|------------------|
| IaC Tool | Terraform |
| Version Control | Git + GitHub |
| CI/CD | GitHub Actions |
| Test Language | Python |
| Security Scan | tfsec |

---

## 3. Functional Requirements

### 3.1 Authentication Module (us-east-1)

| Requirement ID | AUTH-001 |
|----------------|----------|
| **Objective** | Create centralized authentication service shared by both regions |
| **Core Components** | Cognito User Pool + Client + Test User |
| **Deployment Region** | us-east-1 only |

**Functional Summary:**
- Create user pool and client configuration
- Create test user using candidate's real email
- Support user login and JWT token retrieval

---

### 3.2 Compute and Data Module (Multi-Region)

| Requirement ID | COMPUTE-001 |
|----------------|-------------|
| **Objective** | Deploy identical architecture in both regions |
| **Deployment Regions** | us-east-1 + eu-west-1 |

**Component Overview:**

| Component | Function | Description |
|-----------|----------|-------------|
| **API Gateway** | Entry routing | Provides /greet and /dispatch endpoints, protected by Cognito |
| **Lambda 1** | /greet handler | Write to DynamoDB + Send SNS + Return region name |
| **Lambda 2** | /dispatch handler | Trigger ECS Fargate task |
| **DynamoDB** | Data storage | GreetingLogs table, stores call records |
| **ECS Fargate** | Container task | Triggered by Lambda 2, sends SNS message after execution |

---

### 3.3 Test Module

| Requirement ID | TEST-001 |
|----------------|----------|
| **Objective** | Validate multi-region deployment and performance comparison |
| **Test Method** | Python script with concurrent calls to 4 endpoints |

**Test Workflow Summary:**
1. Login to Cognito using candidate's email, get JWT
2. Concurrently call all endpoints in both regions
3. Validate correctness of region field in responses
4. Measure and compare latency differences between regions

---

### 3.4 CI/CD Module

| Requirement ID | CICD-001 |
|----------------|----------|
| **Objective** | Define infrastructure automation workflow |
| **Platform** | GitHub Actions |

**Pipeline Steps:**
| Step | Tool | Purpose |
|------|------|---------|
| Lint/Validate | terraform fmt/validate | Code standard checks |
| Security Scan | tfsec | Security vulnerability scanning |
| Plan | terraform plan | Generate change preview |
| Test (Placeholder) | - | Show test execution location |

---

### 3.5 Functional Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                         Test Client                               │
│                    (Python Test Script)                           │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Cognito (us-east-1)                           │
│                       Authentication                             │
│                    Get JWT Token                                 │
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
            │   Send verification    │
            │   message              │
            └───────────────────────┘
```

---

## 4. SNS Integration Specification

### 4.1 Topic ARN

SNS Topic for verification | `arn:aws:sns:us-east-1:160676960050:Candidate-Verification-Topic`

### 4.2 Payload Format

**Payload sent by Lambda:**
```json
{
  "email": "candidate@example.com",
  "source": "Lambda",
  "region": "us-east-1",
  "repo": "https://github.com/candidate/aws-assessment"
}
```

**Payload sent by ECS:**
```json
{
  "email": "candidate@example.com",
  "source": "ECS",
  "region": "eu-west-1",
  "repo": "https://github.com/candidate/aws-assessment"
}
```

---

## 5. Security Requirements

| Component | Security Requirement | Source |
|-----------|---------------------|--------|
| **API Gateway** | Use Cognito User Pool for authentication | PDF requirement |
| **SNS** | Publish messages to specified Verification Topic | PDF requirement |
| **Lambda** | Use least privilege IAM Role (only DynamoDB write and SNS publish permissions) | Best practice |
| **ECS Fargate** | Task Role uses least privilege (only SNS publish permission) | Best practice |

---

## 6. Cost Optimization

| Component | Optimization Strategy |
|-----------|----------------------|
| ECS Fargate | Use public subnet, avoid NAT Gateway |
| Lambda | Configure memory and timeout based on actual usage |
| DynamoDB | On-demand billing mode |
| API Gateway | Pay-per-use (no additional optimization needed) |

---

## 7. Acceptance Criteria

### 7.1 Infrastructure Acceptance

#### Deployment Success Check
```
Command: terraform apply

Expected Results:
✅ us-east-1 resources created successfully
✅ eu-west-1 resources created successfully
✅ No errors or warnings
```

#### Component Availability Check

| Component | Validation Method | Expected Result |
|-----------|-------------------|-----------------|
| Cognito | Login with test user | Successfully obtain JWT Token |
| API Gateway (us-east-1) | Call /greet with JWT | Return 200 + "us-east-1" |
| API Gateway (eu-west-1) | Call /greet with JWT | Return 200 + "eu-west-1" |
| DynamoDB | Check table items | GreetingLogs has new records |
| ECS Fargate | Call /dispatch | Task starts and completes |

---

### 7.2 Test Script Acceptance

#### Pre-Test Preparation

| Step | Description |
|------|-------------|
| 1 | Ensure infrastructure is deployed in both regions |
| 2 | Obtain test user email and temporary password from Cognito |
| 3 | Confirm test script dependencies are installed (`pip install -r requirements.txt`) |

#### Test Execution

```bash
# Run test script
cd tests
python integration_test.py --email YOUR_EMAIL --password YOUR_PASSWORD
```

#### Test Coverage

```
Test script will validate the following:

┌─────────────────────────────────────────────────────────────────┐
│                        Test Matrix                               │
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
│              │   Validation Points: │                          │
│              │   1. Response status 200                        │
│              │   2. Correct region field                       │
│              │   3. SNS message sent successfully              │
│              │   4. Latency data recorded                      │
│              └──────────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

#### Expected Output

```
=== Test Report ===

[1] Authentication
  ✅ Cognito login successful
  JWT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

[2] API Call Tests
  Endpoint                          Status    Latency      Region
  ──────────────────────────────────────────────────────────────
  us-east-1  /greet            ✅      245ms    us-east-1
  us-east-1  /dispatch         ✅     1850ms    us-east-1
  eu-west-1  /greet            ✅      389ms    eu-west-1
  eu-west-1  /dispatch         ✅     2100ms    eu-west-1

[3] Performance Analysis
  Lambda Latency Comparison:
    us-east-1: 245ms
    eu-west-1: 389ms
    Difference: +144ms (eu-west-1 58.8% slower)

  ECS Latency Comparison:
    us-east-1: 1850ms
    eu-west-1: 2100ms
    Difference: +250ms (eu-west-1 13.5% slower)

[4] SNS Verification
  ✅ 4/4 messages sent to Unleash live Topic
  ✅ Check email to receive confirmation notification

=== Test Complete ===
Total Time: 8.2 seconds
```

#### Test Acceptance Criteria

| Check Item | Pass Criteria |
|------------|---------------|
| Concurrent calls | All 4 endpoints successfully called |
| Status code | All APIs return 200 |
| Region validation | Region field in response matches request region |
| SNS sending | Unleash live received 4 messages |
| Latency output | Complete latency comparison data output to console |

---

### 7.3 SNS Message Acceptance

#### How to Confirm SNS Sending Success?

**Method 1: Via Test Script Output**
```
Test script will display output like:
✅ 4/4 messages sent to Unleash live Topic
```

**Method 2: Wait for Recruitment Team Confirmation**
- Unleash live will automatically monitor SNS Topic
- If message format is correct, they will receive notification
- Candidates who pass technical review will receive interview invitation after deadline

#### SNS Message Format Requirements

Each message triggered by the test script must contain:

| Field | Description | Example |
|-------|-------------|---------|
| email | Candidate email | `candidate@example.com` |
| source | Message source | `Lambda` or `ECS` |
| region | Execution region | `us-east-1` or `eu-west-1` |
| repo | GitHub repository | `https://github.com/user/aws-assessment` |

---

### 7.4 CI/CD Acceptance

#### GitHub Actions Workflow Validation

```bash
# After pushing code, check GitHub Actions page
```

**Validation Checklist:**

| Step | Check Content |
|------|---------------|
| Lint | Code formatting check passed |
| Security Scan | tfsec no critical/high vulnerabilities |
| Plan | terraform plan successfully generated preview |

---

### 7.5 Documentation Acceptance

#### README.md Required Content

| Section | Content Requirements |
|---------|---------------------|
| Project Introduction | Brief description that this is an AWS DevOps Assessment |
| Architecture Diagram | Show deployment architecture for both regions |
| Prerequisites | AWS CLI, Terraform, Python and other tool versions |
| Deployment Steps | Complete commands from `terraform init` → `apply` |
| Test Instructions | How to run test scripts, what parameters are needed |
| Cleanup Instructions | `terraform destroy` command and notes |

---

## 8. Delivery Method

### 8.1 Delivery Checklist

| File/Directory | Description | Required |
|----------------|-------------|----------|
| `terraform/` | IaC code (including main.tf, providers.tf, variables.tf, outputs.tf, backend.tf) | ✅ |
| `terraform/modules/` | Terraform modules (cognito, regional-stack) | ✅ |
| `terraform/environments/` | Environment configuration files (us-east-1, eu-west-1) | ✅ |
| `tests/integration_test.py` | Test script | ✅ |
| `tests/requirements.txt` | Python dependencies | ✅ |
| `.github/workflows/deploy.yml` | CI/CD configuration | ✅ |
| `README.md` | Usage documentation | ✅ |

### 8.2 Submission Checklist

Before submitting repository link, confirm the following:
- [ ] Repository is public
- [ ] README.md contains complete deployment and test instructions
- [ ] Test script can run successfully
- [ ] SNS messages sent successfully (4 messages)
- [ ] Resources destroyed (terraform destroy)
- [ ] Clear commit history

---

## 9. Important Reminders

⚠️ **Resource Cleanup:**
Must execute `terraform destroy` after testing to avoid ongoing costs

📧 **Verification Method:
Automatic verification through messages received via SNS Topic

📅 **Deadline:**
March 15, 2026

---

*Document Version: 3.0*
*Created: 2026-03-02*
*Last Updated: 2026-03-02*
