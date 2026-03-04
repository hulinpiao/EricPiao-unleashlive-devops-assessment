# eu-west-1 Outputs
# Outputs for eu-west-1 region deployment

# ============================================================================
# API Gateway Outputs (For testing)
# ============================================================================

output "api_gateway_endpoint" {
  description = "API Gateway Endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_invoke_url" {
  description = "API Gateway Invoke URL (includes stage)"
  value       = module.api_gateway.invoke_url
}

output "api_greet_url" {
  description = "Full URL for /greet endpoint (uses $default route)"
  value       = "${module.api_gateway.invoke_url}/"
}

output "api_dispatch_url" {
  description = "Full URL for /dispatch endpoint"
  value       = "${module.api_gateway.invoke_url}/dispatch"
}

# ============================================================================
# Lambda Function Outputs (For testing)
# ============================================================================

output "lambda_greet_function_name" {
  description = "Lambda Greet Function Name"
  value       = module.lambda_greet.function_name
}

output "lambda_greet_function_arn" {
  description = "Lambda Greet Function ARN"
  value       = module.lambda_greet.function_arn
}

output "lambda_dispatch_function_name" {
  description = "Lambda Dispatch Function Name"
  value       = module.lambda_dispatch.function_name
}

output "lambda_dispatch_function_arn" {
  description = "Lambda Dispatch Function ARN"
  value       = module.lambda_dispatch.function_arn
}

# ============================================================================
# DynamoDB Outputs (For testing)
# ============================================================================

output "dynamodb_table_name" {
  description = "DynamoDB GreetingLogs Table Name"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB GreetingLogs Table ARN"
  value       = module.dynamodb.table_arn
}

# ============================================================================
# ECS Outputs (For testing)
# ============================================================================

output "ecs_cluster_arn" {
  description = "ECS Fargate Cluster ARN"
  value       = module.ecs_fargate.cluster_arn
}

output "ecs_cluster_name" {
  description = "ECS Fargate Cluster Name"
  value       = module.ecs_fargate.cluster_id
}

output "ecs_task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = module.ecs_fargate.task_definition_arn
}

# ============================================================================
# Cross-Region Testing Instructions
# ============================================================================

output "testing_instructions" {
  description = "Instructions for testing eu-west-1 endpoints"
  value       = <<-EOT
    1. Authenticate with us-east-1 Cognito to get JWT token:
       aws cognito-idp initiate-auth \
         --client-id 3qkmqvl0dchmmubm99td0s39fq \
         --auth-flow USER_PASSWORD_AUTH \
         --region us-east-1 \
         --auth-parameters USERNAME=your_username,PASSWORD=your_password

    2. Test eu-west-1 /greet endpoint:
       curl -H "Authorization: Bearer <JWT_TOKEN>" \
         "${module.api_gateway.invoke_url}/"

    3. Test eu-west-1 /dispatch endpoint:
       curl -X POST \
         -H "Authorization: Bearer <JWT_TOKEN>" \
         -H "Content-Type: application/json" \
         -d '{"email":"your_email@example.com"}' \
         "${module.api_gateway.invoke_url}/dispatch"

    Note: eu-west-1 uses the same Cognito User Pool from us-east-1.
  EOT
}
