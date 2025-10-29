resource "random_password" "sql_database_name" {
  length  = 12
  special = false
  upper   = false
  numeric = false

  keepers = {
    "bump" = 1
  }

  lifecycle {
    ignore_changes = [
      length,
      special,
      upper,
      numeric,
    ]
  }
}

resource "random_password" "synapse_db_username" {
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

resource "random_password" "synapse_db_password" {
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
