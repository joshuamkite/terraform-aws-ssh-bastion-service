#variable "region" {}

# variable "secret_key" {}
# variable "access_key" {}

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

variable "subnet_master" {
  description = "The name for the main (or only!) subnet"
}

variable "subnet_additional" {
  type        = "list"
  description = "list of names for any additional subnets"
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

variable "s3_bucket_name" {
  description = "the name of the s3 bucket where we are storing our go binary"
}
