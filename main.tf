#get aws region for use later in plan
data "aws_region" "current" {
}

#get list of AWS Availability Zones which can be accessed by an AWS account within the region for use later in plan
data "aws_availability_zones" "available" {
}

##########################
#Query for most recent AMI of type debian
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
  name_prefix   = "${var.service_name}-host"
  image_id      = local.bastion_ami_id
  instance_type = var.bastion_instance_type
  iam_instance_profile = element(
    concat(
      aws_iam_instance_profile.bastion_service_assume_role_profile.*.arn,
      aws_iam_instance_profile.bastion_service_profile.*.arn,
    ),
    0,
  )
  associate_public_ip_address = var.public_ip
  security_groups = concat(list("${local.use_VPCs_security_group ? var.vpc_security_group : aws_security_group.bastion_service[0].id}"),
    "${var.security_groups_additional}"
  )
  user_data = data.template_cloudinit_config.config.rendered
  key_name  = var.bastion_service_host_key_name

  lifecycle {
    create_before_destroy = true
  }
}

#######################################################
# ASG section
#######################################################

data "null_data_source" "asg-tags" {
  count = length(keys(var.tags))

  inputs = {
    key                 = element(keys(var.tags), count.index)
    value               = element(values(var.tags), count.index)
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "bastion-service" {
  availability_zones   = data.aws_availability_zones.available.names
  name_prefix          = "${var.service_name}-asg"
  max_size             = var.asg_max
  min_size             = var.asg_min
  desired_capacity     = var.asg_desired
  launch_configuration = aws_launch_configuration.bastion-service-host.name
  vpc_zone_identifier  = var.subnets_asg
  target_group_arns = concat(
    [aws_lb_target_group.bastion-service.arn],
    aws_lb_target_group.bastion-host.*.arn
  )


  lifecycle {
    create_before_destroy = true
  }
  tags = data.null_data_source.asg-tags.*.outputs
}

####################################################
# DNS Section
###################################################

resource "aws_route53_record" "bastion_service" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.route53_fqdn == "" ? local.route53_name_components : var.route53_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.bastion-service.dns_name
    zone_id                = aws_lb.bastion-service.zone_id
    evaluate_target_health = true
  }
}

####################################################
# sample policy for parent account
###################################################

data "template_file" "sample_policies_for_parent_account" {
  count    = local.assume_role_yes
  template = file("${path.module}/sts_assumerole_example/policy_example.tpl")

  vars = {
    aws_profile               = var.aws_profile
    bastion_allowed_iam_group = var.bastion_allowed_iam_group
    assume_role_arn           = var.assume_role_arn
  }
}

