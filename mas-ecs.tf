resource "aws_ecs_task_definition" "ecs_task_definition_mas" {
  count = var.bootstrap_step >= 2 ? 1 : 0

  family                   = "${local.task_name}-mas"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.mas_task_cpu
  memory                   = var.mas_task_memory

  task_role_arn      = aws_iam_role.mas_ecs_task_role.arn
  execution_role_arn = aws_iam_role.mas_ecs_task_execution.arn

  volume {
    name = "config"

    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs_ap_mas.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = local.mas_container_name
      image = "ghcr.io/element-hq/matrix-authentication-service:1.4.1"

      uid = "0"
      gid = "0"

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          name          = "http"
        },
        {
          containerPort = 8081
          hostPort      = 8081
          name          = "health"
        }
      ]

      #healthCheck = {
      #  command     = ["CMD-SHELL", "curl -fsS http://localhost:8081/health || exit 1"]
      #  interval    = 15 # seconds
      #  timeout     = 6  # seconds
      #  retries     = 3
      #  startPeriod = 30 # warm-up before first check
      #}

      #linuxParameters = {
      #  capabilities = {
      #    add = ["SYS_PTRACE"]
      #  }
      #}

      environment = [
        for k, v in local.mas_variables : {
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
          awslogs-group         = aws_cloudwatch_log_group.mas.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs" # shows up as task_name/<container>/<task-id>
        }
      }

      mountPoints = [
        {
          sourceVolume  = "config"
          containerPath = "/app/config"
          readOnly      = false
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service_mas" {
  count = var.bootstrap_step >= 2 ? 1 : 0

  name            = "${local.task_name}-mas"
  cluster         = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.ecs_task_definition_mas[0].arn
  desired_count   = var.mas_desired_count
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_execute_command
  force_new_deployment   = true

  network_configuration {
    subnets         = data.aws_subnets.private_subnets.ids
    security_groups = [aws_security_group.ecs_service.id]
    # assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.namespace.arn
    service {
      discovery_name = local.mas_container_name
      port_name      = "http"
      client_alias {
        dns_name = local.mas_container_name
        port     = "8080"
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg_mas.arn
    container_name   = local.mas_container_name
    container_port   = 8080
  }
}
