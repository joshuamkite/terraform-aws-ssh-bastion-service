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

variable "subnets" {
  type        = "list"
  description = "list of subnets for load balancer and autoscaling group"
  default     = []
}

variable "dns_domain" {
  description = "The domain used for Route53 records"
}

variable "route53_zone_id" {
  description = "Route53 zoneId"
}

variable "iam_authorized_keys_command_url" {
  description = "location for our compiled Go binary - see https://github.com/Fullscreen/iam-authorized-keys-command"
}

variable "create_iam_service_role" {
  type        = "string"
  description = "Whether or not we call the iam_service_role module to create the bastion)servce_role (Boolean value)"
  default     = "1"
}

variable "s3_bucket_name" {
  description = "the name of the s3 bucket where we are storing our go binary"
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
