##################
# security group for bastion_service
##################

resource "aws_security_group" "bastion_service" {
  name_prefix            = var.service_name == "bastion-service" ? format("%s-%s", var.environment_name, var.service_name) : var.service_name
  description            = "Bastion service"
  revoke_rules_on_delete = true
  vpc_id                 = var.vpc
  tags                   = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

##################
# security group rules for bastion_service
##################

# SSH access in from whitelist IP ranges

resource "aws_security_group_rule" "service_ssh_in" {
  count             = local.cidr_blocks_whitelist_service_yes //? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks_whitelist_service
  security_group_id = aws_security_group.bastion_service.id
  description       = "bastion service access"
}

# SSH access in from whitelist IP ranges for Bastion Host - conditional

resource "aws_security_group_rule" "host_ssh_in_cond" {
  count             = local.hostport_whitelisted ? 1 : 0
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = var.cidr_blocks_whitelist_host
  security_group_id = aws_security_group.bastion_service.id
  description       = "bastion HOST access"
}

# Permissive egress policy because we want users to be able to install their own packages 

resource "aws_security_group_rule" "bastion_host_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = -1
  security_group_id = aws_security_group.bastion_service.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "bastion service and host egress"
}

# access from lb cidr ranges for healthchecks 

data "aws_subnet" "lb_subnets" {
  count = length(var.subnets_lb)
  id    = var.subnets_lb[count.index]
}

resource "aws_security_group_rule" "lb_healthcheck_in" {
  security_group_id = aws_security_group.bastion_service.id
  cidr_blocks       = data.aws_subnet.lb_subnets.*.cidr_block
  from_port         = var.lb_healthcheck_port
  to_port           = var.lb_healthcheck_port
  protocol          = "tcp"
  type              = "ingress"
  description       = "access from load balancer CIDR ranges for healthchecks"
}

