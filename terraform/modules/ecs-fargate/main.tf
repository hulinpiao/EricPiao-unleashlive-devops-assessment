# ECS Fargate Module

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = var.task_definition_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "aws-cli"
      image     = var.container_image
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }

      environment = [
        {
          name  = "EMAIL"
          value = "placeholder@example.com"
        },
        {
          name  = "SNS_TOPIC_ARN"
          value = var.sns_topic_arn
        },
        {
          name  = "REGION"
          value = var.aws_region
        },
        {
          name  = "GITHUB_REPO"
          value = var.github_repo
        }
      ]

      # Entrypoint script to send SNS message
      command = [
        "/bin/sh",
        "-c",
        file("${path.module}/userdata.sh")
      ]
    }
  ])

  tags = var.tags
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "task_execution" {
  name = "${var.task_definition_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM Role for ECS Task
resource "aws_iam_role" "task" {
  name = "${var.task_definition_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach policies to task execution role
resource "aws_iam_role_policy_attachment" "task_execution_logging" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "task_execution_sns" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

# IAM Policy for SNS Publish (attached to task execution role)
resource "aws_iam_policy" "sns_publish" {
  name        = "${var.task_definition_name}-sns-publish"
  description = "IAM policy for ECS task to publish to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = var.sns_topic_arn
      }
    ]
  })

  tags = var.tags
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Only allow outbound SNS traffic (restrictive)
  egress {
    description = "Allow HTTPS to SNS endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTP to SNS endpoints"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow DNS
  egress {
    description = "Allow DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
