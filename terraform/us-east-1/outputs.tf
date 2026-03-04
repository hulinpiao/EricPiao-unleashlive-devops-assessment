# us-east-1 Outputs
# These outputs are used for testing and for eu-west-1 deployment

# ============================================================================
# Cognito Outputs (Required for testing and eu-west-1)
# ============================================================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (used by eu-west-1)"
  value       = aws_cognito_user_pool.this.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.this.arn
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID (used for authentication)"
  value       = aws_cognito_user_pool_client.this.id
}

output "cognito_user_pool_url" {
  description = "Cognito User Pool URL (format: https://cognito-idp.{region}.amazonaws.com/{pool_id})"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}

output "cognito_domain" {
  description = "Cognito User Pool Domain (for hosted UI)"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${var.aws_region}.amazoncognito.com"
}

# ============================================================================
# API Gateway Outputs (Required for testing)
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
# Testing Instructions
# ============================================================================

output "testing_instructions" {
  description = "Instructions for testing the deployment"
  value       = <<-EOT
    1. Authenticate with Cognito to get JWT token:
       aws cognito-idp initiate-auth \
         --client-id ${aws_cognito_user_pool_client.this.id} \
         --auth-flow USER_PASSWORD_AUTH \
         --auth-parameters USERNAME=your_username,PASSWORD=your_password

    2. Test /greet endpoint:
       curl -H "Authorization: Bearer <JWT_TOKEN>" \
         "${module.api_gateway.invoke_url}/"

    3. Test /dispatch endpoint:
       curl -X POST \
         -H "Authorization: Bearer <JWT_TOKEN>" \
         -H "Content-Type: application/json" \
         -d '{"email":"your_email@example.com"}' \
         "${module.api_gateway.invoke_url}/dispatch"

    4. Check DynamoDB for logs:
       aws dynamodb scan --table-name ${module.dynamodb.table_name}
  EOT
}
