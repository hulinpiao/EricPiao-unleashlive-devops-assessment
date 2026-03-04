# DynamoDB GreetingLogs Table Variables

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "GreetingLogs"
}

variable "kms_key_arn" {
  description = "KMS key ARN for server-side encryption (empty for AWS managed key)"
  type        = string
  default     = ""
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the DynamoDB table"
  type        = map(string)
  default = {
    Project   = "AWS-DevOps-Assessment"
    ManagedBy = "Terraform"
  }
}
