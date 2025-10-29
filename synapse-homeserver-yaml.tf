locals {
  homeserver_config = {
    server_name : var.server_name
    pid_file : "/data/homeserver.pid"
    report_stats : false
    enable_registration : false
    registration_shared_secret : random_password.synapse_reg_secret.result
    listeners : [
      {
        port : 8008
        tls : false
        type : "http"
        x_forwarded : true
        resources : [
          {
            names : ["client", "federation"]
            compress : false
          }
        ]
      }
    ]
    database : {
      name : "psycopg2"
      txn_limit : 0
      args : {
        user : local.database_master_username     #local.synapse_db_username
        password : local.database_master_password #local.synapse_db_password
        dbname : local.synapse_database_name
        host : aws_rds_cluster.db.endpoint
        port : 5432
        cp_min : 1
        cp_max : 10
      }
    }
    password_config : {
      enabled : false
      #pepper : random_password.synapse_password_pepper.result
      #policy : {
      #  enabled : true
      #  minimum_length : 15
      #  require_digit : true
      #  require_symbol : true
      #  require_lowercase : true
      #  require_uppercase : true
      #}
    }
    matrix_authentication_service : {
      enabled : true
      secret : random_password.mas_synapse_key.result
      endpoint : "https://account.${var.matrix_domain}/"
    }
    media_store_path : "/data/media_store"
    signing_key_path : "/data/${var.server_name}.signing.key"
    trusted_key_servers : [
      {
        server_name : "matrix.org"
      }
    ]
  }
}

resource "random_password" "synapse_reg_secret" {
  length  = 32
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

resource "random_password" "synapse_password_pepper" {
  length  = 32
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

resource "local_file" "homeserver_yaml" {
  content  = yamlencode(local.homeserver_config)
  filename = "${path.module}/config-manager/homeserver.yaml"
}
