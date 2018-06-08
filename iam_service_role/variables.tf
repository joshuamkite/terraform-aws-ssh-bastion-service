variable "bastion_name" {
  description = "the name that will prefix bastion roles/policies"
}


variable "assume_role_arn" {
  description = "arn for role to assume in separate identity account if used"
}
