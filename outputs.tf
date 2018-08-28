output "service_dns_entry" {
  description = "dns-registered url for service and host"
  value       = "${join("", aws_route53_record.bastion_service.*.name)}"
}

output "policy_example_for_parent_account_empty_if_not_used" {
  description = "You must apply an IAM policy with trust realtionship identical or compatible with this in your other AWS account for IAM lookups to function there with STS:AssumeRole and allow users to login"
  value       = "${join("", data.template_file.sample_policies_for_parent_account.*.rendered)}"
}

output "bastion_sg_id" {
  description = "Security Group id of the bastion host"
  value       = "${aws_security_group.bastion_service.id}"
}

output "elb_dns_name" {
  value = "${aws_elb.bastion-service-elb.dns_name}"
}

output "elb_zone_id" {
  value = "${aws_elb.bastion-service-elb.zone_id}"
}

output "bastion_service_assume_role_name" {
  description = "role created for service host asg - if created with assume role"
  value       = "${aws_iam_role.bastion_service_assume_role.*.name}"
}

output "bastion_service_role_name" {
  description = "role created for service host asg - if created without assume role"
  value       = "${aws_iam_role.bastion_service_role.*.name}"
}
