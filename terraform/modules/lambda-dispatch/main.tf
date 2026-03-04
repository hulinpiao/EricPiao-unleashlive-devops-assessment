# Lambda Dispatch Function
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ecs_run_task" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ecs_run_task.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sns_publish" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

resource "aws_iam_role_policy_attachment" "lambda_pass_role" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.pass_role.arn
}

resource "aws_lambda_function" "dispatch" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime     = var.runtime
  timeout     = var.timeout
  memory_size = var.memory_size

  environment {
    variables = {
      ECS_CLUSTER_ARN   = var.ecs_cluster_arn
      ECS_TASK_DEF_ARN  = var.ecs_task_definition_arn
      SUBNET_ID         = var.subnet_id
      SECURITY_GROUP_ID = var.security_group_id
      SNS_TOPIC_ARN     = var.sns_topic_arn
      REGION            = var.aws_region
    }
  }

  tags = var.tags
}

# Archive the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

# IAM Policy for ECS RunTask
resource "aws_iam_policy" "ecs_run_task" {
  name        = "${var.function_name}-ecs-run-task"
  description = "IAM policy for Lambda to run ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = "${var.ecs_cluster_arn}*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = var.ecs_task_role_arn
      }
    ]
  })
}

# IAM Policy for SNS Publish
resource "aws_iam_policy" "sns_publish" {
  name        = "${var.function_name}-sns-publish"
  description = "IAM policy for Lambda to publish to SNS"

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
}

# IAM Policy for passing ECS task role
resource "aws_iam_policy" "pass_role" {
  name        = "${var.function_name}-pass-role"
  description = "IAM policy for Lambda to pass role to ECS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = var.ecs_task_role_arn
      }
    ]
  })
}
