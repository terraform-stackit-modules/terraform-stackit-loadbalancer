#####################################################################################
# "application" example — self-contained, requires only `project_id`.
#
# Deploys an L7 Application Load Balancer (type = "application") with an HTTP listener
# that routes by host + path prefix to a target pool. Builds its own network and
# reserves a public IP, like the basic (network) example.
#####################################################################################

module "network" {
  source  = "terraform-stackit-modules/network/stackit"
  version = ">= 1.0.0"

  project_id  = var.project_id
  name        = "example-alb-network"
  routed      = true
  ipv4_prefix = "10.10.111.0/24"
  ipv4_nameservers = [
    "1.0.0.1",
    "1.1.1.1",
    "8.8.8.8",
  ]

  labels = {
    managed_by = "terraform"
    example    = "application"
  }
}

resource "stackit_public_ip" "alb" {
  project_id = var.project_id
}

module "loadbalancer" {
  source = "../.."

  project_id       = var.project_id
  type             = "application"
  name             = "example-app-lb"
  plan_id          = "p10"
  external_address = stackit_public_ip.alb.ip

  networks = [
    {
      network_id = module.network.network_id
      role       = "ROLE_LISTENERS_AND_TARGETS"
    },
  ]

  application_target_pools = [
    {
      name        = "example-app-pool"
      target_port = 80
      targets = [
        {
          display_name = "example-target"
          # PLACEHOLDER — replace with the PRIVATE IPv4 of your real HTTP backend (the
          # network-interface IPv4 of the server serving on `target_port`). It MUST be an
          # address inside this network's CIDR (10.10.111.0/24 here). With this placeholder the
          # ALB is created/destroyed cleanly, but its health check stays "unhealthy".
          ip = "10.10.111.100"
        },
      ]
      active_health_check = {
        healthy_threshold   = 3
        interval            = "10s"
        interval_jitter     = "5s"
        timeout             = "5s"
        unhealthy_threshold = 3
      }
    },
  ]

  application_listeners = [
    {
      name     = "example-http-listener"
      port     = 80
      protocol = "PROTOCOL_HTTP"
      http = {
        hosts = [
          {
            host = "*.example.com"
            rules = [
              {
                target_pool = "example-app-pool"
                path = {
                  prefix = "/"
                }
              },
            ]
          },
        ]
      }
    },
  ]
}
