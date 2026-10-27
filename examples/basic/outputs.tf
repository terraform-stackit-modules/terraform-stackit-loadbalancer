output "loadbalancer_name" {
  description = "The name of the Load Balancer created by the example."
  value       = module.loadbalancer.loadbalancer_name
}

output "external_address" {
  description = "The external IP address of the Load Balancer created by the example."
  value       = module.loadbalancer.external_address
}

output "public_ip" {
  description = "The public IP reserved for the Load Balancer's external address."
  value       = stackit_public_ip.lb.ip
}

output "backend_ip" {
  description = "The private IP of the backend server behind the Load Balancer."
  value       = local.backend_ip
}

output "network_id" {
  description = "The ID of the network created for the example."
  value       = module.network.network_id
}
