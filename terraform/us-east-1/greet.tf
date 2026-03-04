# /greet Endpoint Configuration

# DynamoDB Table for Greeting Logs
module "dynamodb" {
  source = "../modules/dynamodb"

  table_name = "GreetingLogs"

  tags = merge(
    var.common_tags,
    {
      Function = "Greet"
    }
  )
}

# Lambda Greet Function
module "lambda_greet" {
  source = "../modules/lambda-greet"

  function_name = "${local.project_name}-greet"

  runtime     = "python3.11"
  timeout     = 30
  memory_size = 256

  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn

  sns_topic_arn = var.sns_topic_arn
  aws_region    = var.aws_region

  tags = merge(
    var.common_tags,
    {
      Function = "Greet"
    }
  )
}

# API Gateway
module "api_gateway" {
  source = "../modules/api-gateway"

  api_name = "${local.project_name}-api"

  authorizer_name = "cognito-authorizer"

  # Cognito Configuration
  cognito_user_pool_arn = aws_cognito_user_pool.this.arn
  cognito_user_pool_url = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
  cognito_client_id     = aws_cognito_user_pool_client.this.id

  # Lambda Function ARNs (will be resolved after apply)
  lambda_greet_function_arn  = module.lambda_greet.invoke_arn
  lambda_greet_function_name = module.lambda_greet.function_name

  # Dispatch endpoint Lambda function
  lambda_dispatch_function_arn  = module.lambda_dispatch.invoke_arn
  lambda_dispatch_function_name = module.lambda_dispatch.function_name

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.api_gateway.arn

  tags = merge(
    var.common_tags,
    {
      Component = "API-Gateway"
    }
  )
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.project_name}"
  retention_in_days = 7

  tags = var.common_tags
}
