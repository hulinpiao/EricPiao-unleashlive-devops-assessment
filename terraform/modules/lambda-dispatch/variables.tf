# Lambda Dispatch Function Variables

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "dispatch-function"
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

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role to pass"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for ECS tasks"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
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
    Function  = "Dispatch"
  }
}
