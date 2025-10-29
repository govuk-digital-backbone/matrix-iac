# IAM roles and policies for Element MAS ECS tasks

## ECS Task Role

resource "aws_iam_role" "mas_ecs_task_role" {
  name               = "${local.task_name}-mas-task"
  assume_role_policy = data.aws_iam_policy_document.mas_ecs_task_assume.json
}

data "aws_iam_policy_document" "mas_ecs_task_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "efs_mount_mas" {
  name = "${local.task_name}-mas-efs-mount-policy"
  role = aws_iam_role.mas_ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = [
          data.aws_efs_file_system.by_id.arn,
          "${data.aws_efs_file_system.by_id.arn}:access-point/*"
        ]
      }
    ]
  })
}

## ECS Task Execution Role

resource "aws_iam_role" "mas_ecs_task_execution" {
  name               = "${local.task_name}-mas-exec"
  assume_role_policy = data.aws_iam_policy_document.mas_ecs_execution_assume.json
}

data "aws_iam_policy_document" "mas_ecs_execution_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach_mas" {
  role       = aws_iam_role.mas_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#resource "aws_iam_role_policy" "ecs_exec_custom" {
#  count = var.bootstrap_step >= 3 ? 1 : 0

#  name = "${local.task_name}-exec-policy"
#  role = aws_iam_role.web_ecs_task_execution.id

#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow",
#        Action = [
#          "ssm:GetParameters"
#        ],
#        Resource = [
#          # data.aws_ssm_parameter.planka-admin-password[0].arn,
#        ]
#      }
#    ]
#  })
#}
