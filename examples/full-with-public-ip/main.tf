provider "aws" {
  region = var.aws-region
}

data "aws_availability_zones" "available" {
}

# Localhost IP address

data "http" "ipv4" {
  url = "https://api.ipify.org?format=json"
}

locals {
  localhost_ipv4_cidr = "${jsondecode(data.http.ipv4.body)["ip"]}/32"
}

resource "aws_vpc" "bastion" {
  cidr_block           = "${var.cidr-start}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "bastion-${var.environment-name}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "bastion" {
  vpc_id = aws_vpc.bastion.id
  tags = {
    Name = "bastion-${var.environment-name}-ig"
  }
}

resource "aws_subnet" "bastion" {
  count                   = 1
  vpc_id                  = aws_vpc.bastion.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "${var.cidr-start}.${count.index}.0/24"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "bastion-${var.environment-name}-subnet-${count.index}"
  }
}

resource "aws_route_table" "bastion" {
  vpc_id = aws_vpc.bastion.id
  tags = {
    Name = "bastion-${var.environment-name}-rt"
  }
}

resource "aws_route" "bastion" {
  route_table_id         = aws_route_table.bastion.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bastion.id
}

resource "aws_route_table_association" "bastion" {
  count = 1
  subnet_id      = aws_subnet.bastion[count.index].id
  route_table_id = aws_route_table.bastion.id
}

# Public security group

resource "aws_security_group" "bastion_demo_security_group" {
  count                  = var.use_consumer_vpc == 0 ? 0 : 1
  description            = "VPC security group"
  name                   = "vpc_security_group"
  vpc_id                 = "${aws_vpc.bastion.id}"
  revoke_rules_on_delete = true
  lifecycle { create_before_destroy = true }
  tags = "${merge(map("Name", "VPC security group"), {})}"
}

resource "aws_security_group_rule" "allow_ssh" {
  count             = var.use_consumer_vpc  == 0 ? 0 : 1
  description       = "Allow white-listed SSH connections"
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = "${flatten(concat(list(local.localhost_ipv4_cidr), aws_subnet.bastion.*.cidr_block))}"
  security_group_id = "${aws_security_group.bastion_demo_security_group[0].id}"
}

resource "aws_security_group_rule" "allow_outbound" {
  count             = var.use_consumer_vpc == 0 ? 0 : 1
  description       = "Allow outbound connections"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.bastion_demo_security_group[0].id}"
}

module "ssh-bastion-service" {
  source                        = "../../"
  aws_region                    = var.aws-region
  aws_profile                   = var.aws-profile
  environment_name              = var.environment-name
  vpc                           = aws_vpc.bastion.id
  vpc_security_group            = var.use_consumer_vpc == 1 ? aws_security_group.bastion_demo_security_group[0].id : ""
  use_vpc_security_group        = var.use_consumer_vpc // 1 = use the VPC's security group, 
                                                       // 0 = use the Bastion Service's security group
  subnets_asg                   = flatten([aws_subnet.bastion.*.id])
  subnets_lb                    = flatten([aws_subnet.bastion.*.id])
  cidr_blocks_whitelist_service = "${flatten(concat(list(local.localhost_ipv4_cidr), aws_subnet.bastion.*.cidr_block))}"
#  cidr_blocks_whitelist_host    = "${list(local.localhost_ipv4_cidr)}"
  public_ip                     = true
}
