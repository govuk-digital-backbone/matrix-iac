resource "random_password" "sql_master_username" {
  length  = 8
  special = false
  upper   = false
  numeric = false

  lifecycle {
    ignore_changes = [
      length,
      special,
      upper,
      numeric,
    ]
  }
}

resource "random_password" "sql_master_password" {
  length  = 24
  special = false
  upper   = false

  lifecycle {
    ignore_changes = [
      length,
      special,
      upper,
    ]
  }
}

resource "aws_kms_key" "db_enc" {
  description             = "${local.task_name} KMS key"
  deletion_window_in_days = 10
}

resource "aws_security_group" "rds_synapse" {
  name        = "${local.task_name}-rds-synapse-inbound"
  description = "Allow RDS inbound traffic from ECS Synapse"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "RDS PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ecs_service.id,
      aws_security_group.sqlmgr.id
    ]
  }

  tags = {
    Name = "${local.task_name}-rds-inbound"
  }
}

resource "aws_rds_cluster_parameter_group" "db" {
  name        = "${local.task_name}-cluster-pg"
  family      = "aurora-postgresql15"
  description = "RDS default cluster parameter group"
}

resource "aws_db_subnet_group" "db" {
  name       = "${local.task_name}-db-subnet-group"
  subnet_ids = data.aws_subnets.private_subnets.ids

  tags = {
    Name = "${local.task_name}-db-subnet-group"
  }
}

resource "aws_rds_cluster" "db" {
  cluster_identifier              = "${local.task_name}-cluster-${random_password.sql_database_name.result}"
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = "15.12"
  backup_retention_period         = var.environment_name == "production" ? 14 : 2
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.db.name
  master_username                 = local.database_master_username
  master_password                 = local.database_master_password
  deletion_protection             = (var.environment_name == "production")
  skip_final_snapshot             = true
  kms_key_id                      = aws_kms_key.db_enc.arn
  storage_encrypted               = true
  db_subnet_group_name            = aws_db_subnet_group.db.name
  vpc_security_group_ids = [
    aws_security_group.rds_synapse.id
  ]

  serverlessv2_scaling_configuration {
    max_capacity = var.environment_name == "production" ? 32.0 : 8.0
    min_capacity = var.environment_name == "production" ? 1.0 : 0.5
  }
}

resource "aws_rds_cluster_instance" "db" {
  count                        = var.environment_name == "production" ? 2 : 1
  cluster_identifier           = aws_rds_cluster.db.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.db.engine
  engine_version               = aws_rds_cluster.db.engine_version
  performance_insights_enabled = var.environment_name == "production" ? true : false
}
