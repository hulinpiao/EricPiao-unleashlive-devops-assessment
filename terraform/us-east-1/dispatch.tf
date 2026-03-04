# /dispatch Endpoint Configuration

# Lambda Dispatch Function
module "lambda_dispatch" {
  source = "../modules/lambda-dispatch"

  function_name = "${local.project_name}-dispatch"

  runtime     = "python3.11"
  timeout     = 30
  memory_size = 256

  # ECS Configuration (passed from ECS module outputs)
  ecs_cluster_arn         = module.ecs_fargate.cluster_arn
  ecs_task_definition_arn = module.ecs_fargate.task_definition_arn
  ecs_task_role_arn       = module.ecs_fargate.task_role_arn
  subnet_id               = data.aws_subnets.default.ids[0]
  security_group_id       = module.ecs_fargate.security_group_id

  # SNS Configuration
  sns_topic_arn = var.sns_topic_arn
  aws_region    = var.aws_region

  tags = merge(
    var.common_tags,
    {
      Function = "Dispatch"
    }
  )
}

# ECS Fargate
module "ecs_fargate" {
  source = "../modules/ecs-fargate"

  cluster_name = "${local.project_name}-ecs"

  task_definition_name = "${local.project_name}-dispatch-task"

  task_cpu    = 256
  task_memory = 512

  container_cpu    = 256
  container_memory = 512

  # VPC Configuration - use default VPC and subnets
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  # SNS Configuration
  sns_topic_arn = var.sns_topic_arn
  aws_region    = var.aws_region
  github_repo   = var.github_repo

  log_retention_days = 7

  tags = merge(
    var.common_tags,
    {
      Component = "ECS-Fargate"
      Function  = "Dispatch"
    }
  )
}

# Data sources for default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Update API Gateway module call with dispatch function ARNs
# This is handled by updating the greet.tf api_gateway module call
