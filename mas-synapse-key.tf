resource "random_password" "mas_synapse_key" {
  length  = 32
  special = false
  upper   = true
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
