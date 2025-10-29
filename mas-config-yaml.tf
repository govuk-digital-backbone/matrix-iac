resource "random_bytes" "mas_encryption_key" {
  length = 32
}

locals {
  mas_config = {
    http : {
      listeners : [
        {
          name : "web",
          resources : [
            { name : "discovery" },
            { name : "human" },
            { name : "oauth" },
            { name : "compat" },
            { name : "graphql" },
            { name : "assets" }
          ],
          binds : [
            { address : "[::]:8080" }
          ],
          proxy_protocol : false
        },
        {
          name : "internal",
          resources : [
            { name : "health" }
          ],
          binds : [
            { address : "[::]:8081" }
          ],
          proxy_protocol : false
        }
      ]
      public_base : "https://account.${var.matrix_domain}/"
      issuer : "https://account.${var.matrix_domain}/"
    }
    database : {
      uri : local.mas_database_uri
      max_connections : 10
      min_connections : 0
      connect_timeout : 30
      idle_timeout : 600
      max_lifetime : 1800
    }
    email : {
      from : "\"Authentication Service\" <root@localhost>"
      reply_to : "\"Authentication Service\" <root@localhost>"
      transport : "blackhole"
    }
    secrets : {
      encryption : sensitive(random_bytes.mas_encryption_key.hex)
      keys : [
        {
          key_file : "/app/config/key_rsa_001.pem"
        },
        {
          key_file : "/app/config/key_ec_001.pem"
        }
      ]
    }
    passwords : {
      enabled : false
    }
    account : {
      # Whether users are allowed to change their email addresses.
      #
      # Defaults to `true`.
      email_change_allowed : false

      # Whether users are allowed to change their display names
      #
      # Defaults to `true`.
      # This should be in sync with the policy in the homeserver configuration.
      displayname_change_allowed : false

      # Whether users are allowed to delete their own account
      #
      # Defaults to `true`.
      account_deactivation_allowed : false
    }
    matrix : {
      kind : "synapse"
      homeserver : var.server_name
      secret : random_password.mas_synapse_key.result
      endpoint : "https://synapse.${var.matrix_domain}/"
    }
    upstream_oauth2 : {
      providers : [
        {
          id : var.auth_ulid
          issuer : "https://sso.service.security.gov.uk"
          token_endpoint_auth_method : "client_secret_basic"
          client_id : var.auth_client_id
          client_secret : var.auth_client_secret
          scope : "openid profile email"
          claims_imports : {
            localpart : {
              action : "require"
              template : "{{ user.sub }}"
            }
            displayname : {
              action : "require"
              template : "{{ user.display_name }}"
            }
            account_name : {
              action : "require"
              template : "{{ user.name }}"
            }
            email : {
              action : "require"
              template : "{{ user.email }}"
              set_email_verification : "always"
            }
          }
        }
      ]
    }
  }
}

resource "local_file" "mas_config" {
  content  = yamlencode(local.mas_config)
  filename = "${path.module}/config-manager/mas-config.yaml"
}
