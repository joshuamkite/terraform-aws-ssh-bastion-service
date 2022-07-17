#######################################################
# LB section
#######################################################

resource "aws_lb" "bastion-service" {
  name                             = "${var.service_name}-${var.environment_name}"
  load_balancer_type               = "network"
  internal                         = var.lb_is_internal
  subnets                          = var.subnets_lb
  enable_cross_zone_load_balancing = true
  tags                             = var.tags
}

######################################################
# Listener- Port 22 -service only
######################################################

resource "aws_lb_listener" "bastion-service" {
  load_balancer_arn = aws_lb.bastion-service.arn
  protocol          = "TCP"
  port              = var.bastion_service_port

  default_action {
    target_group_arn = aws_lb_target_group.bastion-service.arn
    type             = "forward"
  }
}

######################################################
# Listener- Port 2222 - service and host - conditional
######################################################

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

######################################################
# Target group service
#######################################################
resource "aws_lb_target_group" "bastion-service" {
  name     = "${var.service_name}-${var.environment_name}-${var.bastion_service_port}"
  protocol = "TCP"
  port     = var.bastion_service_port
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

######################################################	
# Target group 	host - conditional
#######################################################	
resource "aws_lb_target_group" "bastion-host" {
  count    = local.hostport_whitelisted ? 1 : 0
  name     = "${var.service_name}-${var.environment_name}-2222"
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
