resource "aws_ecs_task_definition" "ecs_task_definition_web" {
  count = var.bootstrap_step >= 2 ? 1 : 0

  family                   = "${local.task_name}-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.web_task_cpu
  memory                   = var.web_task_memory

  task_role_arn      = aws_iam_role.web_ecs_task_role.arn
  execution_role_arn = aws_iam_role.web_ecs_task_execution.arn

  volume {
    name = "config"

    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs_ap_web.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = local.web_container_name
      image = "ghcr.io/govuk-digital-backbone/element-web:latest"

      uid = "0"
      gid = "0"

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      healthCheck = {
        command     = ["CMD", "wget -q --spider http://localhost:8080/config.json"]
        interval    = 15 # seconds
        timeout     = 6  # seconds
        retries     = 3
        startPeriod = 10 # warm-up before first check
      }

      #linuxParameters = {
      #  capabilities = {
      #    add = ["SYS_PTRACE"]
      #  }
      #}

      environment = [
        for k, v in local.web_variables : {
          name  = k
          value = v
        }
      ]

      "secrets" : [
        # {
        #   "name" : "DEFAULT_ADMIN_PASSWORD",
        #   "valueFrom" : data.aws_ssm_parameter.planka-admin-password[0].arn
        # },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true" # creates log group if it doesn't exist
          awslogs-group         = aws_cloudwatch_log_group.web.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs" # shows up as task_name/<container>/<task-id>
        }
      }

      mountPoints = [
        {
          sourceVolume  = "config"
          containerPath = "/custom-config"
          readOnly      = false
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service_web" {
  count = var.bootstrap_step >= 2 ? 1 : 0

  name            = "${local.task_name}-web"
  cluster         = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.ecs_task_definition_web[0].arn
  desired_count   = var.web_desired_count
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_execute_command
  force_new_deployment   = true

  network_configuration {
    subnets         = data.aws_subnets.private_subnets.ids
    security_groups = [aws_security_group.ecs_service.id]
    # assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg_web.arn
    container_name   = local.web_container_name
    container_port   = 8080
  }
}
