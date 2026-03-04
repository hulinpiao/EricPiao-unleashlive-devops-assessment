# Lambda Greet Function Variables

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "greet-function"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for sending messages"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to Lambda resources"
  type        = map(string)
  default = {
    Project   = "AWS-DevOps-Assessment"
    ManagedBy = "Terraform"
    Function  = "Greet"
  }
}
