#Get aws account number 
data "aws_caller_identity" "current" {}

#get aws region for use later in plan
data "aws_region" "current" {}

##########################
#Create bastion service role with policies - only needed once per aws account
##########################

module "iam_service_role" {
  source         = "./iam_service_role"
  s3_bucket_name = "${var.s3_bucket_name}"
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
  name        = "bastion_service_host"
  description = "Allow ssh-host and ssh-bastion access to bastion_service_host"

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
  user_data                   = "${data.template_file.bastion_host.rendered}"
  key_name                    = "${var.bastion_service_host_key_name}"
  iam_instance_profile        = "bastion_service_profile"

  tags {
    Name = "bastion_service_host"
  }
}

#######################
# Copy templates files to bastion host
####################

# userdata for bastion host
data "template_file" "bastion_host" {
  template = "${file("${path.module}/user_data_template/bastion_host_cloudinit_config.tpl")}"

  vars {
    bastion_host_name               = "${var.environment_name}-${data.aws_region.current.name}"
    iam_authorized_keys_command_url = "${var.iam_authorized_keys_command_url}"
  }
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

####################################################
# Outputs Section
###################################################

output "service_dns_entry" {
  description = "dns-registered url for service and host"
  value       = "${var.environment_name}-${data.aws_region.current.name}-bastion-service.${var.dns_domain}"
}
