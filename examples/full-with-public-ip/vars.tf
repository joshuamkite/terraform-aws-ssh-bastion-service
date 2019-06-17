variable "aws-profile" {
  default = ""
}

variable "aws-region" {
  default     = "eu-west-1"
  description = "Default AWS region"
}

variable "cidr-start" {
  default     = "10.50"
  description = "Default CIDR block"
}

variable "environment-name" {
  default = "demo"
}
