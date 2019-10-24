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

# Allow SSH access to the service from whitelisted IP ranges when using
# the bation service's security group

resource "aws_security_group_rule" "service_ssh_in" {
  count             = "${var.use_vpc_security_group == 0 && local.cidr_blocks_whitelist_service_yes == 1 ? 1 : 0 }"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks_whitelist_service
  security_group_id = local.selected_security_group
  description       = "bastion service access"
}

# Allow egress when using the bastion service's security group

resource "aws_security_group_rule" "bastion_host_out" {
  count             = var.use_vpc_security_group  == 0 ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = -1
  security_group_id = local.selected_security_group
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "bastion service and host egress"
}

# Allow SSH SSH access to the bastion host from whitelisted IP ranges
# regardless of whether using the bastion service's security group

resource "aws_security_group_rule" "host_ssh_in_cond" {
  count             = "${local.hostport_whitelisted == false ? 0 : 1}"
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks_whitelist_host
  security_group_id = local.selected_security_group
  description       = "bastion HOST access"
}

# Allow health-check traffic from the load-balancer regardless of whether
# using the bastion service's security group

resource "aws_security_group_rule" "lb_healthcheck_in" {
  count             = "${var.use_vpc_security_group  == 0 ? 1 : 0 }"
  security_group_id = local.selected_security_group
  cidr_blocks       = data.aws_subnet.lb_subnets.*.cidr_block
  from_port         = var.lb_healthcheck_port
  to_port           = var.lb_healthcheck_port
  protocol          = "tcp"
  type              = "ingress"
  description       = "Allow bastion service health-check"
}

data "aws_subnet" "lb_subnets" {
  count = length(var.subnets_lb)
  id    = var.subnets_lb[count.index]
}
