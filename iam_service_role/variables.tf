variable "s3_bucket_name" {
  description = "the name of the s3 bucket where we are storing our go binary"
}

variable "create_iam_service_role" {
  type        = "string"
  description = "Whether or not we call the iam_service_role module to create the bastion)servce_role (Boolean value)"
  default     = "1"
}
