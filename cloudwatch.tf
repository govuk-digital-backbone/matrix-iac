resource "aws_cloudwatch_log_group" "synapse" {
  name              = "/ecs/${local.task_name}/synapse"
  retention_in_days = local.log_retention_days
  tags = {
    Name = "${local.task_name}-synapse"
  }
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${local.task_name}/web"
  retention_in_days = local.log_retention_days
  tags = {
    Name = "${local.task_name}-web"
  }
}

resource "aws_cloudwatch_log_group" "mas" {
  name              = "/ecs/${local.task_name}/mas"
  retention_in_days = local.log_retention_days
  tags = {
    Name = "${local.task_name}-mas"
  }
}
