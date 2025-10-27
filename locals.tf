locals {
  task_name = "matrix-${var.matrix_instance_id}"

  ssm_key_prefix = "/matrix/${var.environment_name}/${var.matrix_instance_id}"

  log_retention_days = var.environment_name == "production" ? 365 : 14

  synapse_container_name = "${local.task_name}-synapse"

  database_username = sensitive(random_password.sql_master_username.result)
  database_password = sensitive(random_password.sql_master_password.result)
  database_name     = sensitive("db${random_password.sql_database_name.result}")
  connection_string = sensitive("postgresql://${local.database_username}:${local.database_password}@${aws_rds_cluster.db.endpoint}/${local.database_name}")

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
    }
  )

  web_container_name = "${local.task_name}-web"
  web_variables = merge(
    var.web_variables,
    {
      ELEMENT_WEB_PORT = "8080"
      BUMP             = "2"
    }
  )
}
