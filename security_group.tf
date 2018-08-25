# ##################
# # security group for bastion_service
# ##################

resource "aws_security_group" "bastion_service" {
  name        = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion-service"
  description = "Allow access from the SSH Load Balancer to the Bastion Host"

  vpc_id = "${var.vpc}"
  tags   = "${var.tags}"
}

##################
# security group rules for bastion_service
##################

# SSH access in from whitelist IP ranges to Load Balancer

resource "aws_security_group_rule" "lb_ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = "${var.cidr_blocks_whitelist_service}"
  security_group_id = "${aws_security_group.bastion_service.id}"
}

# SSH access in from whitelist IP ranges to Load Balancer (for Bastion Host - conditional)

resource "aws_security_group_rule" "lb_ssh_in_cond" {
  count             = "${(local.hostport_whitelisted ? 1 : 0) }"
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = ["${var.cidr_blocks_whitelist_host}"]
  security_group_id = "${aws_security_group.bastion_service.id}"
}

# Permissive egress policy because we want users to be able to install their own packages 

resource "aws_security_group_rule" "bastion_host_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = -1
  security_group_id = "${aws_security_group.bastion_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}
