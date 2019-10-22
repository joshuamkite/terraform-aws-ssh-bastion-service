# ##############################################################################
#
# Local variables for the bastion service
#
# ##############################################################################

# Compute a name for the bastion service host

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

# Logic for security group and listeners 
locals {
  hostport_whitelisted    = join(",", var.cidr_blocks_whitelist_host) != ""
  hostport_healthcheck    = var.lb_healthcheck_port == "2222"
}

##########################
# Logic tests for  assume role vs same account 
##########################
locals {
  assume_role_yes = var.assume_role_arn != "" ? 1 : 0
  assume_role_no  = var.assume_role_arn == "" ? 1 : 0
}

##########################
# Logic for using module default userdata sections or not
##########################
locals {
  custom_ssh_populate_no            = var.custom_ssh_populate == "" ? 1 : 0
  custom_authorized_keys_command_no = var.custom_authorized_keys_command == "" ? 1 : 0
  custom_docker_setup_no            = var.custom_docker_setup == "" ? 1 : 0
  custom_systemd_no                 = var.custom_systemd == "" ? 1 : 0
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

