# eu-west-1 Variables

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for sending verification messages"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

# Cognito Configuration (imported from us-east-1)
variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN from us-east-1"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID from us-east-1"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito User Pool Client ID from us-east-1"
  type        = string
}

variable "cognito_user_pool_url" {
  description = "Cognito User Pool URL from us-east-1"
  type        = string
}
