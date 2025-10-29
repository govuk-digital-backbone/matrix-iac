locals {
  task_name = "matrix-${var.matrix_instance_id}"

  ssm_key_prefix = "/matrix/${var.environment_name}/${var.matrix_instance_id}"

  log_retention_days = var.environment_name == "production" ? 365 : 14

  database_master_username = sensitive(random_password.sql_master_username.result)
  database_master_password = sensitive(random_password.sql_master_password.result)

  synapse_container_name = "${local.task_name}-synapse"

  synapse_database_name = sensitive("db${random_password.sql_database_name.result}")
  synapse_db_username   = sensitive(random_password.synapse_db_username.result)
  synapse_db_password   = sensitive(random_password.synapse_db_password.result)
  synapse_variables = merge(
    var.synapse_variables,
    {
      SYNAPSE_SERVER_NAME  = var.matrix_domain
      SYNAPSE_REPORT_STATS = "no"
      SYNAPSE_HTTP_PORT    = "8008"
      SYNAPSE_CONFIG_DIR   = "/data"
      SYNAPSE_CONFIG_PATH  = "/data/homeserver.yaml"
      SYNAPSE_DATA_DIR     = "/data"
      UID                  = "991"
      GID                  = "991"
      SYNAPSE_WORKER       = "synapse.app.homeserver"
      BUMP                 = "4"
    }
  )

  web_container_name = "${local.task_name}-web"
  web_variables = merge(
    var.web_variables,
    {
      ELEMENT_WEB_PORT = "8080"
      BUMP             = "4"
    }
  )

  mas_container_name    = "${local.task_name}-mas"
  mas_database_name     = sensitive("db${random_password.mas_database_name.result}")
  mas_database_username = sensitive(random_password.mas_db_username.result)
  mas_database_password = sensitive(random_password.mas_db_password.result)
  # mas_database_uri      = "postgresql://${local.mas_database_username}:${local.mas_database_password}@${aws_rds_cluster.db.endpoint}:5432/${local.mas_database_name}"
  mas_database_uri = "postgresql://${local.database_master_username}:${local.database_master_password}@${aws_rds_cluster.db.endpoint}:5432/${local.mas_database_name}"
  mas_variables = merge(
    var.mas_variables,
    {
      MAS_CONFIG = "/app/config/config.yaml"
      BUMP       = "8"
    }
  )
}
