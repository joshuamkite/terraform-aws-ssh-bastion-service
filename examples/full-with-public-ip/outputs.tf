output "bastion_sg_id" {
  description = "Security Group id of the bastion host"
  value       = "${module.ssh-bastion-service.bastion_sg_id}"
}

output "lb_dns_name" {
  description = "aws load balancer dns"
  value       = "${module.ssh-bastion-service.lb_dns_name}"
}

output "lb_zone_id" {
  value = "${module.ssh-bastion-service.lb_zone_id}"
}

output "bastion_service_role_name" {
  description = "role created for service host asg - if created without assume role"
  value       = "${module.ssh-bastion-service.bastion_service_role_name}"
}

output "lb_arn" {
  description = "aws load balancer arn"
  value       = "${module.ssh-bastion-service.lb_arn}"
}
