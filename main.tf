locals {
  create_network     = var.create_loadbalancer && var.type == "network"
  create_application = var.create_loadbalancer && var.type == "application"
}

# ─── Observability credential (network LB only) ───────────────────────────────

resource "stackit_loadbalancer_observability_credential" "this" {
  count = local.create_network && var.observability_credential != null ? 1 : 0

  project_id   = var.project_id
  region       = var.region
  display_name = var.observability_credential.display_name
  username     = var.observability_credential.username
  password     = var.observability_credential.password
}

# ─── Network Load Balancer (L4) ───────────────────────────────────────────────

resource "stackit_loadbalancer" "this" {
  count = local.create_network ? 1 : 0

  project_id                        = var.project_id
  region                            = var.region
  name                              = var.name
  plan_id                           = var.plan_id
  external_address                  = var.external_address
  disable_security_group_assignment = var.disable_security_group_assignment

  listeners    = var.network_listeners
  networks     = var.networks
  target_pools = var.network_target_pools
  options      = var.network_options
}

# ─── Application Load Balancer (L7) ───────────────────────────────────────────

resource "stackit_application_load_balancer" "this" {
  count = local.create_application ? 1 : 0

  project_id                               = var.project_id
  region                                   = var.region
  name                                     = var.name
  plan_id                                  = var.plan_id
  external_address                         = var.external_address
  disable_target_security_group_assignment = var.disable_target_security_group_assignment
  labels                                   = var.labels

  listeners    = var.application_listeners
  networks     = var.networks
  target_pools = var.application_target_pools
  options      = var.application_options
}
