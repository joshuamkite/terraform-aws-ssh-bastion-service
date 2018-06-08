output "service_dns_entry" {
  description = "dns-registered url for service and host"
  value       = "${var.environment_name}-${data.aws_region.current.name}-${data.aws_vpc.main.id}-bastion-service.${var.dns_domain}"
}
