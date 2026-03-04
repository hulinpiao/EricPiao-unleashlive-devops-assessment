# API Gateway HTTP API Outputs

output "api_id" {
  description = "API ID"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "API endpoint"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_arn" {
  description = "API ARN"
  value       = aws_apigatewayv2_api.this.arn
}

output "execution_arn" {
  description = "Execution ARN"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "invoke_url" {
  description = "Invoke URL"
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/${aws_apigatewayv2_stage.default.name}"
}

output "stage_arn" {
  description = "Stage ARN"
  value       = aws_apigatewayv2_stage.default.arn
}
