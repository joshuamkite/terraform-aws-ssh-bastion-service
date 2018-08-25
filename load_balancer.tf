#######################################################
# LB section
#######################################################

resource "aws_lb" "bastion-service" {
  name                             = "bastion-${var.vpc}"
  load_balancer_type               = "network"
  internal                         = false
  subnets                          = ["${var.subnets_elb}"]
  enable_cross_zone_load_balancing = true
  tags                             = "${var.tags}"
}

######################################################
# Listener 
#######################################################

# Port 22 only
resource "aws_lb_listener" "bastion-service" {
  load_balancer_arn = "${aws_lb.bastion-service.arn}"
  protocol          = "TCP"
  port              = "22"

  default_action {
    target_group_arn = "${aws_lb_target_group.tunnel-service.arn}"
    type             = "forward"
  }
}

# Port 2222
resource "aws_lb_listener" "bastion-service" {
  count             = "${(local.hostport_whitelisted ? 1 : 0) }"
  load_balancer_arn = "${aws_lb.bastion-service.arn}"
  protocol          = "TCP"
  port              = "2222"

  default_action {
    target_group_arn = "${aws_lb_target_group.tunnel-service.arn}"
    type             = "forward"
  }
}

######################################################
# Target group 
#######################################################
resource "aws_lb_target_group" "bastion-service" {
  name     = "bastion-service"
  protocol = "TCP"
  port     = 22
  vpc_id   = "${var.vpc}"

  health_check {
    healthy_threshold   = "${var.elb_healthy_threshold}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
    interval            = "${var.elb_interval}"
    protocol            = "TCP"
    port                = "${var.elb_healthcheck_port}"
  }
}
