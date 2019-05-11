variable "bastion_instance_type" {
  description = "The virtual hardware to be used for the bastion service host"
  default     = "t2.micro"
}

variable "cidr_blocks_whitelist_host" {
  description = "range(s) of incoming IP addresses to whitelist for the HOST"
  type        = "list"
  default     = []
}

variable "cidr_blocks_whitelist_service" {
  description = "range(s) of incoming IP addresses to whitelist for the SERVICE"
  type        = "list"
  default     = []
}

variable "environment_name" {
  description = "the name of the environment that we are deploying to"
  default     = "staging"
}

variable "vpc" {
  description = "ID for Virtual Private Cloud to apply security policy and deploy stack to"
}

variable "bastion_service_host_key_name" {
  description = "AWS ssh key *.pem to be used for ssh access to the bastion service host"
  default     = ""
}

variable "subnets_lb" {
  type        = "list"
  description = "list of subnets for load balancer - availability zones must match subnets_asg"
  default     = []
}

variable "subnets_asg" {
  type        = "list"
  description = "list of subnets for autoscaling group - availability zones must match subnets_lb"
  default     = []
}

variable "dns_domain" {
  description = "The domain used for Route53 records"
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 zoneId"
  default     = ""
}

variable "bastion_allowed_iam_group" {
  type        = "string"
  description = "Name IAM group, members of this group will be able to ssh into bastion instances if they have provided ssh key in their profile"
  default     = ""
}

variable "tags" {
  type        = "map"
  description = "AWS tags that should be associated with created resources"
  default     = {}
}

##############################
#LB ASG variables
##############################
variable "lb_healthy_threshold" {
  type        = "string"
  description = "Healthy threshold for lb target group"
  default     = "2"
}

variable "lb_unhealthy_threshold" {
  type        = "string"
  description = "Unhealthy threshold for lb target group"
  default     = "2"
}

variable "lb_interval" {
  type        = "string"
  description = "interval for lb target group health check"
  default     = "30"
}

variable "asg_max" {
  type        = "string"
  description = "Max numbers of bastion-service hosts in ASG"
  default     = "2"
}

variable "asg_min" {
  type        = "string"
  description = "Min numbers of bastion-service hosts in ASG"
  default     = "1"
}

variable "asg_desired" {
  type        = "string"
  description = "Desired numbers of bastion-service hosts in ASG"
  default     = "1"
}

variable "aws_region" {}

variable "aws_profile" {}

variable "assume_role_arn" {
  description = "arn for role to assume in separate identity account if used"
  default     = ""
}

variable "lb_healthcheck_port" {
  description = "TCP port to conduct lb target group healthchecks. Acceptable values are 22 or 2222"
  default     = "2222"
}

variable "bastion_vpc_name" {
  description = "define the last part of the hostname, by default this is the vpc ID with magic default value of 'vpc_id' but you can pass a custom string, or an empty value to omit this"
  default     = "vpc_id"
}

variable "container_ubuntu_version" {
  description = "ubuntu version to use for service container. Tested with 16.04 and 18.04"
  default     = "16.04"
}

variable "extra_user_data_content" {
  default     = ""
  description = "Extra user-data to add to the default built-in"
}

variable "extra_user_data_content_type" {
  default     = "text/x-shellscript"
  description = "What format is content in - eg 'text/cloud-config' or 'text/x-shellscript'"
}

variable "extra_user_data_merge_type" {
  # default     = "list(append)+dict(recurse_array)+str()"
  default     = "str(append)"
  description = "Control how cloud-init merges user-data sections"
}

variable "custom_ssh_populate" {
  description = "any value excludes default ssh_populate script used on container launch from userdata"
  default     = ""
}

variable "custom_authorized_keys_command" {
  description = "any value excludes default Go binary iam-authorized-keys built from source from userdata"
  default     = ""
}

variable "custom_docker_setup" {
  description = "any value excludes default docker installation and container build from userdata"
  default     = ""
}

variable "custom_systemd" {
  description = "any value excludes default systemd and hostname change from userdata"
  default     = ""
}

variable "custom_ami_id" {
  description = "id for custom ami if used"
  default     = ""
}

variable "security_groups_additional" {
  description = "additional security group IDs to attach to host instance"
  type        = "list"
  default     = []
}
