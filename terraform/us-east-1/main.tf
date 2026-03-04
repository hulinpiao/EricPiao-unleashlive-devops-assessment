# us-east-1 Infrastructure Root Module

# Locals
locals {
  project_name = "aws-devops-assessment"
  environment  = "us-east-1"
}

# Provider configuration is inherited from providers.tf

# Module: Cognito (DEP-002)
# Module: /greet (DEP-003)
# Module: /dispatch (DEP-004)

# Outputs (DEP-005)
