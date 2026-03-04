# Terraform Infrastructure

> AWS infrastructure as code for multi-region deployment.

---

## Directory Structure

```
terraform/
├── modules/           # Reusable Terraform modules
│   ├── api-gateway/   # HTTP API + Cognito Authorizer
│   ├── dynamodb/      # GreetingLogs table
│   ├── ecs-fargate/   # ECS Cluster + Task Definition
│   ├── lambda-dispatch/  # /dispatch Lambda function
│   └── lambda-greet/  # /greet Lambda function
│
├── us-east-1/         # US East region deployment
│   ├── main.tf        # Main configuration
│   ├── backend.tf     # S3 state backend
│   ├── providers.tf   # AWS provider config
│   ├── cognito.tf     # Cognito User Pool + Client
│   ├── greet.tf       # /greet endpoint resources
│   ├── dispatch.tf    # /dispatch endpoint resources
│   ├── outputs.tf     # Exported values
│   └── terraform.tfvars  # Variable values
│
└── eu-west-1/         # EU West region deployment
    ├── main.tf
    ├── backend.tf
    ├── providers.tf
    ├── greet.tf       # Uses us-east-1 Cognito
    ├── dispatch.tf
    └── terraform.tfvars
```

---

## Modules

| Module | Description |
|--------|-------------|
| **api-gateway** | HTTP API with /greet and /dispatch routes, Cognito JWT authorizer |
| **dynamodb** | GreetingLogs table with pay-per-request billing |
| **ecs-fargate** | ECS cluster with aws-cli container for SNS messaging |
| **lambda-greet** | Python 3.11 Lambda - writes to DynamoDB, sends SNS, returns region |
| **lambda-dispatch** | Python 3.11 Lambda - triggers ECS RunTask |

---

## Manual Operations

> **Note:** CI/CD pipeline handles automated validation. Below are manual commands for local development.

### Initialize

```bash
cd terraform/us-east-1
terraform init
```

### Preview Changes

```bash
terraform plan
```

### Deploy

```bash
terraform apply
```

### View Outputs

```bash
terraform output

# Get specific output
terraform output -raw cognito_pool_id
terraform output -raw api_gateway_url
```

### Destroy

```bash
terraform destroy
```

---

## Deployment Order

1. **Deploy us-east-1 first** - Creates Cognito User Pool (shared across regions)
2. **Copy Cognito config** - Use outputs from us-east-1 for eu-west-1 variables
3. **Deploy eu-west-1** - References us-east-1 Cognito for authentication

```bash
# Step 1: Deploy us-east-1
cd terraform/us-east-1
terraform init
terraform apply

# Step 2: Get Cognito config
terraform output

# Step 3: Update eu-west-1/terraform.tfvars with Cognito values
# cognito_pool_id = "us-east-1_xxxxx"
# cognito_pool_arn = "arn:aws:cognito-idp:us-east-1:..."

# Step 4: Deploy eu-west-1
cd ../eu-west-1
terraform init
terraform apply
```

---

## State Management

Terraform state is stored in S3:

| Region | State File |
|--------|------------|
| us-east-1 | `s3://unleash-assessment-terraform-state/us-east-1/terraform.tfstate` |
| eu-west-1 | `s3://unleash-assessment-terraform-state/eu-west-1/terraform.tfstate` |

---

## Variables

Key variables in `terraform.tfvars`:

| Variable | Description |
|----------|-------------|
| `aws_region` | AWS region for deployment |
| `sns_topic_arn` | SNS topic for verification messages |
| `cognito_pool_id` | Cognito User Pool ID (eu-west-1 only) |
| `cognito_pool_arn` | Cognito User Pool ARN (eu-west-1 only) |

---

*Version: 1.0*
*Last Updated: 2026-03-04*
