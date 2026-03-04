# ECS Fargate Module Variables

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "task_definition_name" {
  description = "Name of the ECS task definition"
  type        = string
  default     = "dispatch-task"
}

variable "task_cpu" {
  description = "CPU units for the task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512
}

variable "container_image" {
  description = "Container image to use"
  type        = string
  default     = "amazon/aws-cli:latest"
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory for the container in MB"
  type        = number
  default     = 512
}

variable "vpc_id" {
  description = "VPC ID where ECS tasks will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for sending messages"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/user/aws-assessment"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to ECS resources"
  type        = map(string)
  default = {
    Project   = "AWS-DevOps-Assessment"
    ManagedBy = "Terraform"
    Component = "ECS-Fargate"
  }
}
