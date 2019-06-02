provider "aws" {
  region = var.aws-region
}

data "aws_availability_zones" "available" {
}

resource "aws_vpc" "bastion" {
  cidr_block           = "${var.cidr-start}.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "bastion-${var.environment-name}-vpc"
  }
}

resource "aws_subnet" "bastion" {
  count = 1

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "${var.cidr-start}.${count.index}.0/24"
  vpc_id            = aws_vpc.bastion.id

  tags = {
    Name = "bastion-${var.environment-name}-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "bastion" {
  vpc_id = aws_vpc.bastion.id

  tags = {
    Name = "bastion-${var.environment-name}-ig"
  }
}

resource "aws_route_table" "bastion" {
  vpc_id = aws_vpc.bastion.id

  tags = {
    Name = "bastion-${var.environment-name}-rt"
  }
}

resource "aws_route" "bastion-ipv4-out" {
  route_table_id         = aws_route_table.bastion.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bastion.id
}

resource "aws_route_table_association" "bastion" {
  count = 1

  subnet_id      = aws_subnet.bastion[count.index].id
  route_table_id = aws_route_table.bastion.id
}

variable "everyone-cidr" {
  default     = "0.0.0.0/0"
  description = "Everyone"
}

# To create the bastion service, subnets need to already exist
# This is currently a limitation of Terraform: https://github.com/hashicorp/terraform/issues/12570
# Since Terraform version 0.12.0 you can either: 
# Comment out the bastion service, apply, uncomment and apply again (as for Terraform 0.11.x)
# Or simply run the plan twice - first time will give an error like below, simply run again

# Error: Provider produced inconsistent final plan

# When expanding the plan for
# module.ssh-bastion-service.aws_autoscaling_group.bastion-service to include
# new values learned so far during apply, provider "aws" produced an invalid new
# value for .availability_zones: was known, but now unknown.

# This is a bug in the provider, which should be reported in the provider's own
# issue tracker.

module "ssh-bastion-service" {
  source = "joshuamkite/ssh-bastion-service/aws"
  # source                        = "../../"
  aws_region                    = var.aws-region
  aws_profile                   = var.aws-profile
  environment_name              = var.environment-name
  vpc                           = aws_vpc.bastion.id
  subnets_asg                   = flatten([aws_subnet.bastion.*.id])
  subnets_lb                    = flatten([aws_subnet.bastion.*.id])
  cidr_blocks_whitelist_service = [var.everyone-cidr]
  public_ip                     = true
}