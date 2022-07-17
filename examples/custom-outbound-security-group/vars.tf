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

variable "bastion_service_port" {
  type        = number
  description = "Port for containerised ssh daemon"
  default     = 443
}

variable "custom_cidr" {
  type        = list(string)
  description = "CIDR for custom security gtoup ingress"
  default     = ["0.0.0.0/0"]
}
