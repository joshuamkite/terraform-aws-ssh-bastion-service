# ##############################################################################
#
# Bastion Service Load Balancer
#
# ##############################################################################

# The load balancer

resource "aws_lb" "bastion-service" {
  name                             = md5(format("${var.service_name}-%s", var.vpc))
  load_balancer_type               = "network"
  internal                         = var.lb_is_internal
  subnets                          = var.subnets_lb
  enable_cross_zone_load_balancing = true
  tags                             = var.tags
}

# A Listener on Port 22 

resource "aws_lb_listener" "bastion-service" {
  load_balancer_arn = aws_lb.bastion-service.arn
  protocol          = "TCP"
  port              = "22"

  default_action {
    target_group_arn = aws_lb_target_group.bastion-service.arn
    type             = "forward"
  }
}

# A target group for port 22

resource "aws_lb_target_group" "bastion-service" {
  name     = md5(format("${var.service_name}-%s", var.vpc))
  protocol = "TCP"
  port     = 22
  vpc_id   = var.vpc
  health_check {
    healthy_threshold   = var.lb_healthy_threshold
    unhealthy_threshold = var.lb_unhealthy_threshold
    interval            = var.lb_interval
    protocol            = "TCP"
    port                = var.lb_healthcheck_port
  }
  tags = var.tags
}

resource "aws_autoscaling_attachment" "bastion-service" {
  autoscaling_group_name = "${aws_autoscaling_group.bastion-service.id}"
  alb_target_group_arn   = "${aws_lb_target_group.bastion-service.arn}"
}

# ##############################################################################
#
# Bastion host Load Balancer
#
# If the bastion host is white-listed for some set of CIDR blocks, 
# create a listener on port 2222 
#
# ##############################################################################

resource "aws_lb_listener" "bastion-host" {
  count             = local.hostport_whitelisted ? 1 : 0
  load_balancer_arn = aws_lb.bastion-service.arn
  protocol          = "TCP"
  port              = "2222"
  default_action {
    target_group_arn = aws_lb_target_group.bastion-host[0].arn
    type             = "forward"
  }
}

# And a target group

resource "aws_lb_target_group" "bastion-host" {
  count    = local.hostport_whitelisted ? 1 : 0
  name     = "bastion-host"
  protocol = "TCP"
  port     = 2222
  vpc_id   = var.vpc
  health_check {
    healthy_threshold   = var.lb_healthy_threshold
    unhealthy_threshold = var.lb_unhealthy_threshold
    interval            = var.lb_interval
    protocol            = "TCP"
    port                = var.lb_healthcheck_port
  }

  tags = var.tags
}

# Then associate the target group with the bastion service auto-scaling group
resource "aws_autoscaling_attachment" "bastion_host" {
  count                  = local.hostport_whitelisted ? 1 : 0
  autoscaling_group_name = "${aws_autoscaling_group.bastion-service.id}"
#  elb                    = "${aws_lb.bastion-service.id}"
  alb_target_group_arn   = "${aws_lb_target_group.bastion-host[0].arn}"
}
