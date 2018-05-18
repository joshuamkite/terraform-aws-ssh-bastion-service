#Get aws account number
data "aws_caller_identity" "current" {}

#get aws region for use later in plan
data "aws_region" "current" {}

##########################
#Create bastion service role with policies - only needed once per aws account
##########################

module "iam_service_role" {
  source       = "./iam_service_role"
  bastion_name = "${var.environment_name}-${data.aws_region.current.name}"
}

##########################
#Create user-data for bastion ec2 instance
##########################

module "bastion_user_data" {
  source                    = "./user-data"
  environment_name          = "${var.environment_name}"
  bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
}

##########################
#Query for most recent AMI of type debian for use as host
##########################

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name = "name"

    values = ["debian-stretch-hvm-x86_64-*"]
  }

  owners = ["379101102735"] # Debian
}

# ##################
# #Security section
# ##################

# # security group for bastion_host

resource "aws_security_group" "instance" {
  name        = "${var.environment_name}-${data.aws_region.current.name}-bastion"
  description = "Allow ssh-host and ssh-bastion access to ${var.environment_name}-${data.aws_region.current.name}"

  # SSH access from whitelist IP ranges - to be used for sshd service containers
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
    cidr_blocks = "${var.cidr_blocks_whitelist_host}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${var.vpc}"
  tags   = "${var.tags}"
}

############################
# additional NIC per subnet for 'dual' homing
###########################

resource "aws_network_interface" "lan_additional" {
  count = "${length(var.subnet_additional)}"

  subnet_id       = "${var.subnet_additional[count.index]}"
  security_groups = ["${aws_security_group.instance.id}"]

  tags {
    Name = "additional_network_interface-${count.index}"
  }

  attachment {
    instance     = "${aws_instance.bastion_service_host.id}"
    device_index = 1
  }
}

# #########################
# # Container Host section
# ##########################

# # #Configure debian host
resource "aws_instance" "bastion_service_host" {
  ami                         = "${data.aws_ami.debian.id}"
  instance_type               = "${var.bastion_instance_type}"
  subnet_id                   = "${var.subnet_master}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.instance.id}"]
  user_data                   = "${module.bastion_user_data.user_data_bastion}"
  key_name                    = "${var.bastion_service_host_key_name}"
  iam_instance_profile        = "${module.iam_service_role.instance_profile}"

  tags = "${merge(
      map(
        "Name", "${var.environment_name}-${data.aws_region.current.name}-bastion",
        "Environment", "${var.environment_name}",
        "Region", "${data.aws_region.current.name}",
      ),
      "${var.tags}"
    )}"
}

####################################################
# DNS Section
###################################################

resource "aws_route53_record" "bastion_service" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.environment_name}-${data.aws_region.current.name}-bastion-service.${var.dns_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.bastion_service_host.public_ip}"]
}
