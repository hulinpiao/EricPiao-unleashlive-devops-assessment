# API Gateway HTTP API Variables

variable "api_name" {
  description = "Name of the API"
  type        = string
  default     = "assessment-api"
}

variable "api_description" {
  description = "Description of the API"
  type        = string
  default     = "AWS DevOps Assessment API"
}

variable "stage_name" {
  description = "Name of the deployment stage"
  type        = string
  default     = "$default"
}

variable "authorizer_name" {
  description = "Name of the Cognito authorizer"
  type        = string
  default     = "cognito-authorizer"
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool (optional, leave empty if using external Cognito)"
  type        = string
  default     = ""
}

variable "cognito_user_pool_url" {
  description = "URL of the Cognito User Pool (e.g., https://cognito-idp.us-east-1.amazonaws.com/us-east-1_xxxxx)"
  type        = string
  default     = ""
}

variable "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for API access logs"
  type        = string
}

variable "detailed_metrics_enabled" {
  description = "Enable detailed metrics"
  type        = bool
  default     = true
}

variable "throttling_burst_limit" {
  description = "Throttling burst limit"
  type        = number
  default     = 100
}

variable "throttling_rate_limit" {
  description = "Throttling rate limit"
  type        = number
  default     = 50
}

variable "tags" {
  description = "Tags to apply to API Gateway resources"
  type        = map(string)
  default = {
    Project   = "AWS-DevOps-Assessment"
    ManagedBy = "Terraform"
    Component = "API-Gateway"
  }
}
