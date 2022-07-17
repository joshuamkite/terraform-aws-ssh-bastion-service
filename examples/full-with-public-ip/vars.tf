variable "aws_region" {
  default     = "eu-west-1"
  description = "Default AWS region"
}

variable "cidr-start" {
  default     = "10.50"
  description = "Default CIDR block"
}

variable "environment_name" {
  default = "demo"
}

variable "tags" {
  type        = map(string)
  description = "tags aplied to all resources"
  default     = {}
}

variable "everyone_cidr" {
  default     = "0.0.0.0/0"
  description = "Everyone"
}

locals {
  default_tags = {
    Name = "bastion-service-${var.environment_name}"
  }
}
