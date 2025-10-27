locals {
  elementweb_config = {
    default_server_name : var.server_name
    default_server_config : {
        "m.homeserver" : {
            "base_url": "https://synapse.matrix.${var.server_name}"
        }
    }
    brand: "Internal Discuss"
  }
}

resource "local_file" "elementweb_config" {
  content  = jsonencode(local.elementweb_config)
  filename = "${path.module}/config-manager/config.json"
}
