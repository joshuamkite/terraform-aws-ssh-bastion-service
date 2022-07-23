
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.default_tags
  }
}

data "aws_availability_zones" "available" {
}

resource "aws_vpc" "bastion" {
  cidr_block           = "${var.cidr-start}.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "bastion" {
  count             = 1
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "${var.cidr-start}.${count.index}.0/24"
  vpc_id            = aws_vpc.bastion.id
}

resource "aws_internet_gateway" "bastion" {
  vpc_id = aws_vpc.bastion.id
}

resource "aws_route_table" "bastion" {
  vpc_id = aws_vpc.bastion.id
}

resource "aws_route" "bastion-ipv4-out" {
  route_table_id         = aws_route_table.bastion.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bastion.id
}

resource "aws_route_table_association" "bastion" {
  count          = 1
  subnet_id      = aws_subnet.bastion[count.index].id
  route_table_id = aws_route_table.bastion.id
}

module "ssh-bastion-service" {
  source = "joshuamkite/ssh-bastion-service/aws"
  # source                        = "../../"
  aws_region                    = var.aws_region
  environment_name              = var.environment_name
  vpc                           = aws_vpc.bastion.id
  subnets_asg                   = flatten([aws_subnet.bastion.*.id])
  subnets_lb                    = flatten([aws_subnet.bastion.*.id])
  cidr_blocks_whitelist_service = [var.everyone_cidr]
  public_ip                     = true
  bastion_instance_types        = ["t3.micro"]
}
