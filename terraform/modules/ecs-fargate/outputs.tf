# ECS Fargate Module Outputs

output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_revision" {
  description = "ECS Task Definition Revision"
  value       = aws_ecs_task_definition.this.revision
}

output "task_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ECS Task Role ARN"
  value       = aws_iam_role.task.arn
}

output "security_group_id" {
  description = "Security Group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}
