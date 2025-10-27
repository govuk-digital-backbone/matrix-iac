resource "aws_ecs_task_definition" "ecs_task_definition" {
  count = var.bootstrap_step >= 2 ? 1 : 0

  family                   = "${local.task_name}-synapse"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.synapse_task_cpu
  memory                   = var.synapse_task_memory

  task_role_arn      = aws_iam_role.synapse_ecs_task_role.arn
  execution_role_arn = aws_iam_role.synapse_ecs_task_execution.arn

  volume {
    name = "data"

    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs_ap_synapse.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = local.synapse_container_name
      image = "${var.synapse_container_image}:${var.synapse_container_image_tag}"

      uid = "991"
      gid = "991"

      portMappings = [
        {
          containerPort = 8008
          hostPort      = 8008
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -fsS http://localhost:8008/health || exit 1"]
        interval    = 15     # seconds
        timeout     = 6      # seconds
        retries     = 3
        startPeriod = 30     # warm-up before first check
      }

      #linuxParameters = {
      #  capabilities = {
      #    add = ["SYS_PTRACE"]
      #  }
      #}

      environment = [
        for k, v in local.synapse_variables : {
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
          awslogs-group         = aws_cloudwatch_log_group.synapse.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs" # shows up as task_name/<container>/<task-id>
        }
      }

      mountPoints = [
        {
          sourceVolume  = "data"
          containerPath = "/data"
          readOnly      = false
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service_synapse" {
  count = var.bootstrap_step >= 2 ? 1 : 0

  name            = "${local.task_name}-synapse"
  cluster         = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.ecs_task_definition[0].arn
  desired_count   = var.synapse_desired_count
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_execute_command
  force_new_deployment   = true

  network_configuration {
    subnets         = data.aws_subnets.private_subnets.ids
    security_groups = [aws_security_group.ecs_service.id]
    # assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_tg_synapse.arn
    container_name   = local.synapse_container_name
    container_port   = 8008
  }
}
