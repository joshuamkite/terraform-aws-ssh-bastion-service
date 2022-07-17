resource "aws_security_group" "custom" {
  name                   = "custom"
  description            = "custom security group"
  revoke_rules_on_delete = true
  vpc_id                 = aws_vpc.bastion.id
  tags                   = var.tags
}

resource "aws_security_group_rule" "in_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.custom_cidr
  security_group_id = aws_security_group.custom.id
  description       = "custom security group rule"
}

resource "aws_security_group_rule" "out_53" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.custom.id
  description       = "custom security group rule"
}

resource "aws_security_group_rule" "out_80_tcp" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.custom.id
  description       = "custom security group rule"
}

resource "aws_security_group_rule" "out_443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.custom.id
  description       = "custom security group rule"
}
