variable "environment_name" {
  description = "the name of the environment that we are deploying to"
  default     = "staging"
}

variable "bastion_allowed_iam_group" {
  type        = "string"
  description = "Name IAM group, members of this group will be able to ssh into bastion instances if they have provided ssh key in their profile"
}

variable "vpc" {
  type        = "string"
  description = "the vpc we are deploying to"
}
