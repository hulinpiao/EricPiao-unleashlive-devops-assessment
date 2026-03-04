# eu-west-1 Infrastructure Root Module

# Locals
locals {
  project_name = "aws-devops-assessment"
  environment  = "eu-west-1"
  # Add region suffix to avoid naming conflicts with us-east-1
  resource_suffix = "eu"
}

# Provider configuration is inherited from providers.tf

# Module: /greet (DEP-008)
# Module: /dispatch (DEP-009)

# Outputs (DEP-010 之后添加)
