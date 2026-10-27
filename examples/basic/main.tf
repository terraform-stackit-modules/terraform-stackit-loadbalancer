#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module.
#
# "basic" — end-to-end Network Load Balancer (L4), self-contained (project_id only):
#   network (+ security group allowing TCP/80) → a backend server running nginx on
#   port 80 (via cloud-init) → a reserved public IP → a Load Balancer whose target
#   pool points at the server's private IP.
#
# The Load Balancer refuses to finish creating unless at least one target is ACTIVE
# (accepts a TCP connection on the target port), so this example provisions a real
# backend. cloud-init installs nginx AFTER Terraform considers the server created, so
# a time_sleep gives nginx time to come up before the Load Balancer health-checks it.
#####################################################################################

locals {
  network_cidr = "10.10.110.0/24"
  # Fixed private IP for the backend NIC so the Load Balancer target is known at plan time.
  backend_ip = "10.10.110.10"
}

module "network" {
  source  = "terraform-stackit-modules/network/stackit"
  version = ">= 1.0.0"

  project_id  = var.project_id
  name        = "example-lb-network"
  routed      = true
  ipv4_prefix = local.network_cidr
  ipv4_nameservers = [
    "1.0.0.1",
    "1.1.1.1",
    "8.8.8.8",
  ]

  create_security_group      = true
  security_group_description = "Allow inbound HTTP (80) for the Load Balancer health check, all egress"
  security_group_rules = [
    {
      direction  = "ingress"
      ether_type = "IPv4"
      ip_range   = "0.0.0.0/0"
      protocol   = { name = "tcp" }
      port_range = { min = 80, max = 80 }
    },
    {
      direction  = "egress"
      ether_type = "IPv4"
      ip_range   = "0.0.0.0/0"
      protocol   = { name = "tcp" }
    },
  ]

  labels = {
    managed_by = "terraform"
    example    = "basic"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Backend server running nginx on port 80 (the Load Balancer target).
module "backend" {
  source  = "terraform-stackit-modules/compute/stackit"
  version = ">= 1.0.0"

  project_id        = var.project_id
  name              = "example-lb-backend"
  machine_type      = var.machine_type
  availability_zone = "eu01-1"

  boot_volume = {
    source_type = "image"
    source_id   = var.image_id
    size        = 8
  }

  create_key_pair = true
  public_key      = trimspace(tls_private_key.this.public_key_openssh)

  network_interfaces = {
    primary = {
      network_id         = module.network.network_id
      name               = "example-lb-backend-nic"
      security_group_ids = [module.network.security_group_id]
      ipv4               = local.backend_ip
    }
  }

  user_data = <<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
  EOT

  labels = {
    managed_by = "terraform"
    example    = "basic"
  }
}

# Give cloud-init time to install and start nginx before the Load Balancer health-checks
# the target — the server is "created" (API) well before cloud-init finishes.
resource "time_sleep" "wait_for_nginx" {
  depends_on      = [module.backend]
  create_duration = "120s"
}

# Reserve a public IP to expose the Load Balancer on.
resource "stackit_public_ip" "lb" {
  project_id = var.project_id
}

module "loadbalancer" {
  source = "../.."

  project_id       = var.project_id
  type             = "network"
  name             = "example-load-balancer"
  plan_id          = "p10"
  external_address = stackit_public_ip.lb.ip

  networks = [
    {
      network_id = module.network.network_id
      role       = "ROLE_LISTENERS_AND_TARGETS"
    },
  ]

  network_target_pools = [
    {
      name        = "example-target-pool"
      target_port = 80
      targets = [
        {
          display_name = "example-backend"
          ip           = local.backend_ip
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

  network_listeners = [
    {
      display_name = "example-listener"
      port         = 80
      protocol     = "PROTOCOL_TCP"
      target_pool  = "example-target-pool"
      tcp = {
        idle_timeout = "90s"
      }
    },
  ]

  # Ensure nginx is up on the backend before the Load Balancer health-checks it.
  depends_on = [time_sleep.wait_for_nginx]
}
