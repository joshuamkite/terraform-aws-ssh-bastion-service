variable "bastion_name" {
  description = "the name that will prefix bastion roles/policies"
}

variable "create_iam_service_role" {
  description = "create bastion service role and policies (standalone account) boolean"
  default     = "1"
}
