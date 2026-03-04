# /greet Endpoint Configuration (eu-west-1)

# DynamoDB Table for Greeting Logs
module "dynamodb" {
  source = "../modules/dynamodb"

  table_name = "GreetingLogs"

  tags = merge(
    var.common_tags,
    {
      Function = "Greet"
      Region   = "eu-west-1"
    }
  )
}

# Lambda Greet Function
module "lambda_greet" {
  source = "../modules/lambda-greet"

  function_name = "${local.project_name}-greet-${local.resource_suffix}"

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
      Region   = "eu-west-1"
    }
  )
}

# API Gateway
module "api_gateway" {
  source = "../modules/api-gateway"

  api_name = "${local.project_name}-api-${local.resource_suffix}"

  authorizer_name = "cognito-authorizer"

  # Cognito Configuration (imported from us-east-1)
  cognito_user_pool_arn = var.cognito_user_pool_arn
  cognito_user_pool_url = var.cognito_user_pool_url
  cognito_client_id     = var.cognito_client_id

  # Lambda Function ARNs
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
      Region    = "eu-west-1"
    }
  )
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.project_name}"
  retention_in_days = 7

  tags = var.common_tags
}
