variable "aws-profile" {
  default = ""
}

variable "aws-region" {
  description = "Default AWS region"
}

variable "cidr-start" {
  default     = "10.50"
  description = "Default CIDR block"
}

variable "environment-name" {
  default = "demo"
}

variable "use_consumer_vpc" {
  description = "If 1, use the security group of the VPC provided by the consumer"
  type        = number
  default     = 0
}

