# ─── Core ─────────────────────────────────────────────────────────────────────

variable "project_id" {
  description = "STACKIT project ID to which the Load Balancer is associated."
  type        = string
}

variable "type" {
  description = <<-EOT
    Which Load Balancer to create:
      - `network`     : an L4 Network Load Balancer (stackit_loadbalancer) — TCP/UDP/TCP_PROXY/
                        TLS_PASSTHROUGH. Uses the `network_*` inputs.
      - `application` : an L7 Application Load Balancer (stackit_application_load_balancer) — HTTP/
                        HTTPS with host/path routing and optional WAF. Uses the `application_*` inputs.
    NOTE: STACKIT exposes these as two SEPARATE resources (not one resource with a type flag), so
    this module gates them with `count` on `type`. Provide only the input set matching `type`.
  EOT
  type        = string
  default     = "network"

  validation {
    condition     = contains(["network", "application"], var.type)
    error_message = "type must be either \"network\" or \"application\"."
  }
}

variable "create_loadbalancer" {
  description = "Whether to create the Load Balancer (and, for type=network, its observability credential). Set to false to disable all resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Load balancer name."
  type        = string
}

variable "region" {
  description = "The resource region. If not defined, the provider region is used."
  type        = string
  default     = null
}

variable "plan_id" {
  description = "The service plan ID. For network LBs: `p10`, `p50`, `p250`, `p750`. For application LBs: see `stackit beta alb plans`. Defaults to the provider default when null."
  type        = string
  default     = null
}

variable "external_address" {
  description = "External Load Balancer IP address where this Load Balancer is exposed. For type=application it is not changeable after creation."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels (key-value) for the Load Balancer. Only applied to type=application (the network LB resource has no labels)."
  type        = map(string)
  default     = null
}

variable "networks" {
  description = <<-EOT
    List of networks that listeners and targets reside in (shared by both types). Each entry:
      - `network_id` : STACKIT/OpenStack network ID.
      - `role`       : `ROLE_UNSPECIFIED`, `ROLE_LISTENERS_AND_TARGETS`, `ROLE_LISTENERS`, or `ROLE_TARGETS`.
  EOT
  type = list(object({
    network_id = string
    role       = string
  }))
  default = []

  validation {
    condition = alltrue([
      for n in var.networks :
      contains(["ROLE_UNSPECIFIED", "ROLE_LISTENERS_AND_TARGETS", "ROLE_LISTENERS", "ROLE_TARGETS"], n.role)
    ])
    error_message = "Each network role must be one of: ROLE_UNSPECIFIED, ROLE_LISTENERS_AND_TARGETS, ROLE_LISTENERS, ROLE_TARGETS."
  }
}

# ─── Network LB (L4) — used when type = "network" ─────────────────────────────

variable "disable_security_group_assignment" {
  description = "[network] Disable automatic security group assignment to the LB's targets (for targets outside the LB network/SNA). Not changeable after creation."
  type        = bool
  default     = null
}

variable "network_listeners" {
  description = <<-EOT
    [network] L4 listeners (max 20). Each entry:
      - `port`         (required) : port to listen on.
      - `protocol`     (required) : `PROTOCOL_TCP`, `PROTOCOL_UDP`, `PROTOCOL_TCP_PROXY`, `PROTOCOL_TLS_PASSTHROUGH`, `PROTOCOL_UNSPECIFIED`.
      - `target_pool`  (required) : name of the network target pool this listener forwards to.
      - `display_name`            : listener display name.
      - `tcp` / `udp`             : `{ idle_timeout = "300s" }` protocol-specific options.
  EOT
  type = list(object({
    port         = number
    protocol     = string
    target_pool  = string
    display_name = optional(string)
    tcp          = optional(object({ idle_timeout = optional(string) }))
    udp          = optional(object({ idle_timeout = optional(string) }))
  }))
  default = null

  validation {
    condition = var.network_listeners == null || alltrue([
      for l in coalesce(var.network_listeners, []) :
      contains(["PROTOCOL_UNSPECIFIED", "PROTOCOL_TCP", "PROTOCOL_UDP", "PROTOCOL_TCP_PROXY", "PROTOCOL_TLS_PASSTHROUGH"], l.protocol)
    ])
    error_message = "Each network listener protocol must be one of: PROTOCOL_UNSPECIFIED, PROTOCOL_TCP, PROTOCOL_UDP, PROTOCOL_TCP_PROXY, PROTOCOL_TLS_PASSTHROUGH."
  }
}

variable "network_target_pools" {
  description = <<-EOT
    [network] L4 target pools (max 20). Each entry:
      - `name`        (required) : pool name (referenced by a network listener's `target_pool`).
      - `target_port` (required) : port each target listens on.
      - `targets`     (required) : list of `{ display_name, ip }` backends.
      - `active_health_check`    : `{ healthy_threshold, interval, interval_jitter, timeout, unhealthy_threshold }`.
      - `session_persistence`    : `{ use_source_ip_address = true }` (Maglev sticky by source IP).
  EOT
  type = list(object({
    name        = string
    target_port = number
    targets = list(object({
      display_name = string
      ip           = string
    }))
    active_health_check = optional(object({
      healthy_threshold   = optional(number)
      interval            = optional(string)
      interval_jitter     = optional(string)
      timeout             = optional(string)
      unhealthy_threshold = optional(number)
    }))
    session_persistence = optional(object({
      use_source_ip_address = optional(bool)
    }))
  }))
  default = null
}

variable "network_options" {
  description = <<-EOT
    [network] Optional L4 functionality:
      - `acl`                  : set of CIDR ranges allowed to reach the LB.
      - `private_network_only` : if true, LB reachable only via a private network IP.
      - `observability`        : ARGUS logs/metrics push config (not changeable after creation).
  EOT
  type = object({
    acl                  = optional(set(string))
    private_network_only = optional(bool)
    observability = optional(object({
      logs    = optional(object({ credentials_ref = optional(string), push_url = optional(string) }))
      metrics = optional(object({ credentials_ref = optional(string), push_url = optional(string) }))
    }))
  })
  default = null
}

variable "observability_credential" {
  description = <<-EOT
    [network] Optional observability credential (username/password for the ARGUS service). Its
    `credentials_ref` output can be wired into `network_options.observability.{logs,metrics}.credentials_ref`.
      - `display_name`, `username`, `password` (password is sensitive).
  EOT
  type = object({
    display_name = string
    username     = string
    password     = string
  })
  default   = null
  sensitive = true
}

# ─── Application LB (L7) — used when type = "application" ──────────────────────

variable "disable_target_security_group_assignment" {
  description = "[application] Disable target security group assignment to allow targets outside the given network. Not changeable after creation."
  type        = bool
  default     = null
}

variable "application_listeners" {
  description = <<-EOT
    [application] L7 listeners (max 20). Each entry:
      - `name`     (required) : unique listener name.
      - `port`     (required) : listen port.
      - `protocol` (required) : `PROTOCOL_HTTP`, `PROTOCOL_HTTPS`, or `PROTOCOL_UNSPECIFIED`.
      - `http`     (required) : `{ hosts = [{ host, rules = [{ target_pool, path {prefix|exact_match}?,
                                headers?, query_parameters?, cookie_persistence {name, ttl}?, web_socket? }] }] }`.
      - `https`               : `{ certificate_config = { certificate_ids = [...] } }` for TLS termination.
      - `waf_config_name`     : name of a WAF configuration to enable on this listener.
  EOT
  type = list(object({
    name            = string
    port            = number
    protocol        = string
    waf_config_name = optional(string)
    http = object({
      hosts = list(object({
        host = string
        rules = list(object({
          target_pool = string
          web_socket  = optional(bool)
          path = optional(object({
            prefix      = optional(string)
            exact_match = optional(string)
          }))
          cookie_persistence = optional(object({
            name = string
            ttl  = string
          }))
          headers = optional(set(object({
            name        = string
            exact_match = optional(string)
          })))
          query_parameters = optional(set(object({
            name        = string
            exact_match = optional(string)
          })))
        }))
      }))
    })
    https = optional(object({
      certificate_config = object({
        certificate_ids = set(string)
      })
    }))
  }))
  default = null

  validation {
    condition = var.application_listeners == null || alltrue([
      for l in coalesce(var.application_listeners, []) :
      contains(["PROTOCOL_UNSPECIFIED", "PROTOCOL_HTTP", "PROTOCOL_HTTPS"], l.protocol)
    ])
    error_message = "Each application listener protocol must be one of: PROTOCOL_UNSPECIFIED, PROTOCOL_HTTP, PROTOCOL_HTTPS."
  }
}

variable "application_target_pools" {
  description = <<-EOT
    [application] L7 target pools (max 20). Each entry:
      - `name`        (required) : pool name (referenced by an application rule's `target_pool`).
      - `target_port` (required) : port each target listens on.
      - `targets`     (required) : set of `{ display_name, ip }` backends.
      - `active_health_check`    : `{ healthy_threshold, interval, interval_jitter, timeout, unhealthy_threshold }`.
      - `tls_config`             : `{}` to enable TLS bridging to the targets.
  EOT
  type = list(object({
    name        = string
    target_port = number
    targets = set(object({
      display_name = string
      ip           = string
    }))
    active_health_check = optional(object({
      healthy_threshold   = optional(number)
      interval            = optional(string)
      interval_jitter     = optional(string)
      timeout             = optional(string)
      unhealthy_threshold = optional(number)
    }))
    tls_config = optional(object({}))
  }))
  default = null
}

variable "application_options" {
  description = <<-EOT
    [application] Optional L7 functionality:
      - `acl`                  : set of CIDR ranges allowed to reach the LB.
      - `private_network_only` : if true, LB reachable only via a private network IP.
  EOT
  type = object({
    acl                  = optional(set(string))
    private_network_only = optional(bool)
  })
  default = null
}
