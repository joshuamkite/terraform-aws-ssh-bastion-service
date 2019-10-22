# ##############################################################################
#
# Bastion Service security group - only used if the bastion service does not
# add rules to a security group in the parent VPC
#
# ##############################################################################

resource "aws_security_group" "bastion_service" {
  count                  = var.use_vpc_security_group == 1 ? 0 : 1
  name_prefix            = var.service_name == "bastion-service" ? format("%s-%s", var.environment_name, var.service_name) : var.service_name
  description            = "Bastion service"
  revoke_rules_on_delete = true
  vpc_id                 = var.vpc
  tags                   = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion service security group rules

# Allow SSH access to the service from whitelisted IP ranges


resource "aws_security_group_rule" "service_ssh_in" {
  count             = "${var.use_vpc_security_group == 0 && local.cidr_blocks_whitelist_service_yes == 1 ? 1 : 0}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks_whitelist_service
  security_group_id = "${var.use_vpc_security_group == 1 && var.vpc_security_group != "" ? var.vpc_security_group : aws_security_group.bastion_service[0].id}"
  description       = "bastion service access"
}

# Allow SSH SSH access to the bastion host from whitelisted IP ranges

resource "aws_security_group_rule" "host_ssh_in_cond" {
  count             = "${local.hostport_whitelisted != "" ? 0 : 1}"
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks_whitelist_host
  security_group_id = var.use_vpc_security_group == 1 && var.vpc_security_group != "" ? var.vpc_security_group : aws_security_group.bastion_service[0].id
  description       = "bastion HOST access"
}

# If configured in a stand-alone VPC, allow outbound egress so that users
# may install packages in the Docker image of their choosing.  If installing
# the bastion host in an existing VPC, use the VPC's policy 

resource "aws_security_group_rule" "bastion_host_out" {
  count             = "${var.use_vpc_security_group  == 1 ? 0 : 1}"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = -1
  security_group_id = var.use_vpc_security_group == 1 && var.vpc_security_group != "" ? var.vpc_security_group : aws_security_group.bastion_service[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "bastion service and host egress"
}

# Allow health-check traffic from the load-balancer 

data "aws_subnet" "lb_subnets" {
  count = length(var.subnets_lb)
  id    = var.subnets_lb[count.index]
}

resource "aws_security_group_rule" "lb_healthcheck_in" {
  security_group_id = "${var.use_vpc_security_group == 1 && var.vpc_security_group != "" ? var.vpc_security_group : aws_security_group.bastion_service[0].id}"
  cidr_blocks       = data.aws_subnet.lb_subnets.*.cidr_block
  from_port         = var.lb_healthcheck_port
  to_port           = var.lb_healthcheck_port
  protocol          = "tcp"
  type              = "ingress"
  description       = "Allow bastion service health-check"
}
