output "policy_example_for_parent_account_empty_if_not_used" {
  description = "You must apply an IAM policy with trust relationship identical or compatible with this in your other AWS account for IAM lookups to function there with STS:AssumeRole and allow users to login"
  value       = "${module.ssh-bastion-service.policy_example_for_parent_account_empty_if_not_used}"
}

output "bastion_sg_id" {
  description = "Security Group id of the bastion host"
  value       = "${module.ssh-bastion-service.bastion_sg_id}"
}

output "lb_dns_name" {
  description = "aws load balancer dns"
  value       = "${module.ssh-bastion-service.lb_dns_name}"
}

output "lb_zone_id" {
  value       = "${module.ssh-bastion-service.lb_zone_id}"
}

output "bastion_service_assume_role_name" {
  description = "role created for service host asg - if created with assume role"
  value       = "${module.ssh-bastion-service.lb_dns_name}"
}

output "bastion_service_role_name" {
  description = "role created for service host asg - if created without assume role"
    value       = "${module.ssh-bastion-service.bastion_service_role_name}"
}

output "lb_arn" {
  description = "aws load balancer arn"
  value       = "${module.ssh-bastion-service.lb_arn}"
}
