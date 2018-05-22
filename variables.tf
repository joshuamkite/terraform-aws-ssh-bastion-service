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
}

variable "subnets_elb" {
  type        = "list"
  description = "list of subnets for load balancer"
  default     = []
}

variable "subnets_asg" {
  type        = "list"
  description = "list of subnets for autoscaling group"
  default     = []
}

variable "dns_domain" {
  description = "The domain used for Route53 records"
}

variable "route53_zone_id" {
  description = "Route53 zoneId"
}

variable "bastion_allowed_iam_group" {
  type        = "string"
  description = "Name IAM group, members of this group will be able to ssh into bastion instances if they have provided ssh key in their profile"
}

variable "tags" {
  type        = "map"
  description = "AWS tags that should be associated with created resources"
  default     = {}
}

##############################
#ELB ASG variables
##############################
variable "elb_healthy_threshold" {
  type        = "string"
  description = "Healthy threshold for ELB"
  default     = "2"
}

variable "elb_unhealthy_threshold" {
  type        = "string"
  description = "Unhealthy threshold for ELB"
  default     = "2"
}

variable "elb_timeout" {
  type        = "string"
  description = "timeout for ELB"
  default     = "3"
}

variable "elb_interval" {
  type        = "string"
  description = "interval for ELB health check"
  default     = "30"
}

variable "elb_idle_timeout" {
  type        = "string"
  description = "The time in seconds that the connection is allowed to be idle"
  default     = "300"
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

variable "iam_identities_account_bastion_role_arn" {
  type        = "string"
  description = "arn for role in identites account that bastion assumes"
}

variable "create_iam_service_role" {
  description = "create bastion service role and policies (standalone account) boolean"
  default     = "0"
}
