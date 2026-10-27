output "loadbalancer_name" {
  description = "The name of the Application Load Balancer created by the example."
  value       = module.loadbalancer.loadbalancer_name
}

output "external_address" {
  description = "The external IP address of the Application Load Balancer."
  value       = module.loadbalancer.external_address
}

output "public_ip" {
  description = "The public IP reserved for the ALB's external address."
  value       = stackit_public_ip.alb.ip
}
