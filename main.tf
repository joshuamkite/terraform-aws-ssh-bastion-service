#Get aws account number
data "aws_caller_identity" "current" {}

#get aws region for use later in plan
data "aws_region" "current" {}

#get list of AWS Availability Zones which can be accessed by an AWS account within the region for use later in plan
data "aws_availability_zones" "available" {}

#get vpc data to whitelist internal CIDR range for Load Balanacer
data "aws_vpc" "main" {
  id = "${var.vpc}"
}

##########################
#Create bastion service role with policies 
##########################

module "iam_service_role" {
  source          = "./iam_service_role"
  bastion_name    = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}"
  assume_role_arn = "${var.assume_role_arn}"
}

##########################
#Create user-data for bastion ec2 instance 
##########################
locals {
  assume_role_yes = "${var.assume_role_arn != "" ? 1 : 0}"
  assume_role_no  = "${var.assume_role_arn == "" ? 1 : 0}"
}

data "template_file" "user_data_assume_role" {
  count    = "${local.assume_role_yes}"
  template = "${file("${path.module}/user_data/bastion_host_cloudinit_config_assume_role.tpl")}"

  vars {
    bastion_host_name         = "${var.environment_name}-${data.aws_region.current.name}"
    authorized_command_code   = "${indent(8, file("user_data/iam_authorized_keys_code/main.go"))}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
    authorized_command_code   = "${indent(8, file("user_data/iam_authorized_keys_code/main.go"))}"
    vpc                       = "${var.vpc}"
    assume_role_arn           = "${var.assume_role_arn}"
  }
}

data "template_file" "user_data_same_account" {
  count    = "${local.assume_role_no}"
  template = "${file("${path.module}/user_data/bastion_host_cloudinit_config.tpl")}"

  vars {
    bastion_host_name         = "${var.environment_name}-${data.aws_region.current.name}"
    authorized_command_code   = "${indent(8, file("user_data/iam_authorized_keys_code/main.go"))}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
    authorized_command_code   = "${indent(8, file("user_data/iam_authorized_keys_code/main.go"))}"
    vpc                       = "${var.vpc}"
  }
}

# ##################
# # security group for bastion_host
# ##################

resource "aws_security_group" "instance" {
  name        = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion"
  description = "Allow ssh-host and ssh-bastion access to ${var.environment_name}-${data.aws_region.current.name}-${var.vpc}"

  # SSH access from whitelist IP ranges for sshd service containers 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.cidr_blocks_whitelist_service}"
  }

  # SSH access from whitelist IP ranges - to be used for host sshd
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_blocks_whitelist_host}"]
  }

  # SSH access from anywhere within vpc to accomodate load balancer for sshd service containers 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]
  }

  # Permissive egress policy because we want users to be able to install their own packages 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${var.vpc}"
  tags   = "${var.tags}"
}

##########################
#Query for most recent AMI of type debian for use as host
##########################

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-*"]
  }

  owners = ["379101102735"] # Debian
}

############################
#Launch configuration for service host
############################

resource "aws_launch_configuration" "bastion-service-host" {
  name_prefix                 = "bastion-service-host"
  image_id                    = "${data.aws_ami.debian.id}"
  instance_type               = "${var.bastion_instance_type}"
  iam_instance_profile        = "${module.iam_service_role.instance_profile}"
  associate_public_ip_address = "true"

  #https://github.com/hashicorp/terraform/issues/575
  #https://github.com/hashicorp/terraform/commit/3b67537dfabc1a65eb17e92849da5e64737daae3
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = "${element(
    concat(data.template_file.user_data_assume_role.*.rendered,
           data.template_file.user_data_same_account.*.rendered),
    0)}"

  key_name = "${var.bastion_service_host_key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

#######################################################
# ASG section
#######################################################

resource "aws_autoscaling_group" "bastion-service-asg" {
  availability_zones   = ["${data.aws_availability_zones.available.names}"]
  name_prefix          = "bastion-service-asg"
  max_size             = "${var.asg_max}"
  min_size             = "${var.asg_min}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.bastion-service-host.name}"
  vpc_zone_identifier  = ["${var.subnets_asg}"]
  load_balancers       = ["${aws_elb.bastion-service-elb.name}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = [{
    key                 = "Name"
    value               = "${var.environment_name}-${data.aws_region.current.name}-bastion"
    propagate_at_launch = true
  },
    {
      key                 = "Environment"
      value               = "${var.environment_name}"
      propagate_at_launch = true
    },
    {
      key                 = "Region"
      value               = "data.aws_region.current.name"
      propagate_at_launch = true
    },
  ]
}

#######################################################
# ELB section
#######################################################

resource "aws_elb" "bastion-service-elb" {
  name = "bastion-service-elb"

  # Sadly can't use availabilty zones for classic load balancer - see https://github.com/terraform-providers/terraform-provider-aws/issues/1063
  # availability_zones = ["${data.aws_availability_zones.available.names}"]
  subnets = ["${var.subnets_elb}"]

  security_groups = ["${aws_security_group.instance.id}"]

  listener {
    instance_port     = 22
    instance_protocol = "TCP"
    lb_port           = 22
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = "${var.elb_healthy_threshold}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
    timeout             = "${var.elb_timeout}"
    target              = "TCP:22"
    interval            = "${var.elb_interval}"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = "${var.elb_idle_timeout}"
  connection_draining         = true
  connection_draining_timeout = 300
}

####################################################
# DNS Section
###################################################

resource "aws_route53_record" "bastion_service" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.environment_name}-${data.aws_region.current.name}-${var.vpc}-bastion-service.${var.dns_domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.bastion-service-elb.dns_name}"
    zone_id                = "${aws_elb.bastion-service-elb.zone_id}"
    evaluate_target_health = true
  }
}
