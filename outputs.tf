output "user_data_bastion" {
  description = "cloud-config user data used to initialize bastion at start up"
  value       = "${module.bastion_user_data.user_data_bastion}"
}

output "user_data_ami_linux" {
  description = "cloud-config user data used to initialize ami linux instances which are run as ecs/k8s nodes"
  value       = "${module.bastion_user_data.user_data_ami_linux}"
}

output "service_dns_entry" {
  description = "dns-registered url for service and host"
  value       = "${var.environment_name}-${data.aws_region.current.name}-bastion-service.${var.dns_domain}"
}

output "service_dns_entry" {
  description = "dns-registered url for bastion service"
  value       = "${var.environment_name}-${data.aws_region.current.name}-bastion-service.${var.dns_domain}"
}
