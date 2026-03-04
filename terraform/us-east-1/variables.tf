# us-east-1 Variables

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
