##########################
#Create local for bastion hostname
##########################

locals {
  bastion_vpc_name = var.bastion_vpc_name == "vpc_id" ? var.vpc : var.bastion_vpc_name
  bastion_host_name = var.bastion_host_name == "" ? join(
    "-",
    compact(
      [
        var.environment_name,
        data.aws_region.current.name,
        local.bastion_vpc_name,
      ],
    ),
  ) : var.bastion_host_name
}

##########################
# Logic for security group and listeners 
##########################
locals {
  hostport_whitelisted = join(",", var.cidr_blocks_whitelist_host) != ""
  hostport_healthcheck = var.lb_healthcheck_port == "2222"
}

##########################
# Logic tests for  assume role vs same account 
##########################
locals {
  assume_role_yes      = var.assume_role_arn != "" ? 1 : 0
  assume_role_no       = var.assume_role_arn == "" ? 1 : 0
  assume_role_yes_bool = var.assume_role_arn != "" ? true : false
}

##########################
# Logic for using module default userdata sections or not
##########################
locals {
  custom_ssh_populate_no            = var.custom_ssh_populate == "" ? 1 : 0
  custom_authorized_keys_command_no = var.custom_authorized_keys_command == "" ? true : false
  custom_docker_setup_no            = var.custom_docker_setup == "" ? true : false
  custom_systemd_no                 = var.custom_systemd == "" ? true : false
}

##########################
# Logic for using module default or custom ami
##########################

locals {
  bastion_ami_id = var.custom_ami_id == "" ? data.aws_ami.debian.id : var.custom_ami_id
}

##########################
# Logic for using cidr_blocks_whitelist_service ONLY if provided
##########################

locals {
  cidr_blocks_whitelist_service_yes = join(",", var.cidr_blocks_whitelist_service) != "" ? 1 : 0
}

##########################
# Construct route53 name for historical behaviour where used
##########################

locals {
  route53_name_components = "${local.bastion_host_name}-${var.service_name}.${var.dns_domain}"
}


############################
# User Data Templates
############################
locals {
  systemd = templatefile("${path.module}/user_data/systemd.tftpl", {
    bastion_host_name    = local.bastion_host_name
    bastion_service_port = var.bastion_service_port
    vpc                  = var.vpc
  })
  ssh_populate_assume_role = templatefile("${path.module}/user_data/ssh_populate_assume_role.tftpl", {
    assume_role_arn = var.assume_role_arn
  })
  ssh_populate_same_account = file("${path.module}/user_data/ssh_populate_same_account.tftpl")
  docker_setup = templatefile("${path.module}/user_data/docker_setup.tftpl", {
    bastion_service_port     = var.bastion_service_port
    container_ubuntu_version = var.container_ubuntu_version
  })
  iam_authorized_keys_command = templatefile("${path.module}/user_data/iam-authorized-keys-command.tftpl", {
    authorized_command_code   = file("${path.module}/user_data/iam_authorized_keys_code/main.go")
    bastion_allowed_iam_group = var.bastion_allowed_iam_group
  })
}

####################################################
# sample policy for parent account
###################################################
locals {
  sample_policies_for_parent_account = templatefile("${path.module}/sts_assumerole_example/policy_example.tftpl", {
    aws_profile               = var.aws_profile
    bastion_allowed_iam_group = var.bastion_allowed_iam_group
    assume_role_arn           = var.assume_role_arn
    }
  )
}
