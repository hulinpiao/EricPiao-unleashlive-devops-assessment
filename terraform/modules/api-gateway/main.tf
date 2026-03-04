# API Gateway HTTP API Module

# HTTP API
resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = var.api_description

  tags = var.tags
}

# Cognito Authorizer
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  name             = var.authorizer_name
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = replace(var.cognito_user_pool_url, "/$", "") # Remove trailing slash
  }
}

# Integration for /greet endpoint
resource "aws_apigatewayv2_integration" "greet" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  description      = "Integration for /greet endpoint"

  connection_type        = "INTERNET"
  integration_uri        = var.lambda_greet_function_arn
  payload_format_version = "2.0"
}

# Integration for /dispatch endpoint
resource "aws_apigatewayv2_integration" "dispatch" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  description      = "Integration for /dispatch endpoint"

  connection_type        = "INTERNET"
  integration_uri        = var.lambda_dispatch_function_arn
  payload_format_version = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "greet" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.greet.id}"

  authorization_type = var.cognito_user_pool_arn != "" ? "JWT" : "NONE"
  authorizer_id      = var.cognito_user_pool_arn != "" ? aws_apigatewayv2_authorizer.cognito.id : null
}

resource "aws_apigatewayv2_route" "dispatch" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /dispatch"
  target    = "integrations/${aws_apigatewayv2_integration.dispatch.id}"

  authorization_type = var.cognito_user_pool_arn != "" ? "JWT" : "NONE"
  authorizer_id      = var.cognito_user_pool_arn != "" ? aws_apigatewayv2_authorizer.cognito.id : null
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = var.cloudwatch_log_group_arn

    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = var.detailed_metrics_enabled
    throttling_burst_limit   = var.throttling_burst_limit
    throttling_rate_limit    = var.throttling_rate_limit
  }

  tags = var.tags
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "greet" {
  statement_id  = "AllowAPIGatewayInvokeGreet"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_greet_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "dispatch" {
  statement_id  = "AllowAPIGatewayInvokeDispatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_dispatch_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*/*"
}

# Variables for Lambda function ARNs
variable "lambda_greet_function_arn" {
  description = "Invoke ARN of the Greet Lambda function"
  type        = string
}

variable "lambda_greet_function_name" {
  description = "Name of the Greet Lambda function"
  type        = string
}

variable "lambda_dispatch_function_arn" {
  description = "Invoke ARN of the Dispatch Lambda function"
  type        = string
}

variable "lambda_dispatch_function_name" {
  description = "Name of the Dispatch Lambda function"
  type        = string
}
