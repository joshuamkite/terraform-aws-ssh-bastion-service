variable "s3_bucket_name" {
  description = "the name of the s3 bucket where we are storing our go binary"
}

variable "create_iam_service_role" {
  description = "create bastion service role and policies (standalone account) boolean"
  default     = "1"
}
