output "service_dns_entry" {
  description = "dns-registered url for service and host"
  value       = "${var.environment_name}-${data.aws_region.current.name}-${data.aws_vpc.main.id}-bastion-service.${var.dns_domain}"
}

output "policy_example_for_parent_account_empty_if_not_used" {
  description = "You must apply an IAM policy with trust realtionship identical or compatible with this in your other AWS account for IAM lookups to function there with STS:AssumeRole and allow users to login"
  value       = "${join("", data.template_file.sample_policies_for_parent_account.*.rendered)}"
}

output "bastion_sg_id" {
  description = "Security Group id of the bastion host"
  value = "${aws_security_group.bastion_service.id}"
}