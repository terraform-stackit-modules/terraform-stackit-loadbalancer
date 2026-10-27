output "type" {
  description = "The Load Balancer type that was created (`network` or `application`)."
  value       = var.type
}

output "loadbalancer_name" {
  description = "The name of the created Load Balancer (null when create_loadbalancer is false)."
  value = local.create_network ? stackit_loadbalancer.this[0].name : (
    local.create_application ? stackit_application_load_balancer.this[0].name : null
  )
}

output "external_address" {
  description = "The external IP address where the Load Balancer is exposed."
  value = local.create_network ? stackit_loadbalancer.this[0].external_address : (
    local.create_application ? stackit_application_load_balancer.this[0].external_address : null
  )
}

output "private_address" {
  description = "The transient private Load Balancer IP address (can change over time)."
  value = local.create_network ? stackit_loadbalancer.this[0].private_address : (
    local.create_application ? stackit_application_load_balancer.this[0].private_address : null
  )
}

# ─── Network LB specific ──────────────────────────────────────────────────────

output "security_group_id" {
  description = "[network] ID of the auto-created security group allowing targets to receive LB traffic (null unless a network LB is created)."
  value       = local.create_network ? stackit_loadbalancer.this[0].security_group_id : null
}

output "load_balancer_security_group_id" {
  description = "[network] Egress security group ID of the LB's internal machines — use as remote_security_group_id on target VMs for cross-network access (null unless a network LB is created)."
  value       = local.create_network ? stackit_loadbalancer.this[0].load_balancer_security_group_id : null
}

output "observability_credentials_ref" {
  description = "[network] The credentials reference of the created observability credential (null when none)."
  value       = local.create_network && var.observability_credential != null ? stackit_loadbalancer_observability_credential.this[0].credentials_ref : null
  sensitive   = true
}

# ─── Application LB specific ──────────────────────────────────────────────────

output "target_security_group" {
  description = "[application] Security group that allows targets to receive traffic from the ALB (null unless an application LB is created)."
  value       = local.create_application ? stackit_application_load_balancer.this[0].target_security_group : null
}

output "load_balancer_security_group" {
  description = "[application] Security group permitting traffic from the ALB to the targets (null unless an application LB is created)."
  value       = local.create_application ? stackit_application_load_balancer.this[0].load_balancer_security_group : null
}
