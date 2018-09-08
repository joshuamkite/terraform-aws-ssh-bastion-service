##########################
#Create local for bastion hostname
##########################

locals {
  bastion_vpc_name  = "${var.bastion_vpc_name == "vpc_id" ? var.vpc : var.bastion_vpc_name}"
  bastion_host_name = "${join("-", compact(list(var.environment_name, data.aws_region.current.name, local.bastion_vpc_name)))}"
}

# Logic tests for security group and listeners 

locals {
  hostport_whitelisted = "${(join(",", var.cidr_blocks_whitelist_host) !="") }"
  hostport_healthcheck = "${(var.lb_healthcheck_port == "2222")}"
}

##########################
# Logic tests for  user-data 
##########################
locals {
  assume_role_yes = "${var.assume_role_arn != "" ? 1 : 0}"
  assume_role_no  = "${var.assume_role_arn == "" ? 1 : 0}"
}

##########################
# Logic tests for using module default ssh_populate script
##########################
locals {
  custom_ssh_populate_yes = "${var.custom_ssh_populate != "" ? 1 : 0}"
  custom_ssh_populate_no  = "${var.custom_ssh_populate == "" ? 1 : 0}"
}

##########################
# Logic tests for using module default authorized_keys_command code
##########################

locals {
  custom_authorized_keys_command_yes = "${var.custom_authorized_keys_command != "" ? 1 : 0}"
  custom_authorized_keys_command_no  = "${var.custom_authorized_keys_command == "" ? 1 : 0}"
}

##########################
# Logic tests for using module default docker_setup
##########################
locals {
  custom_docker_setup_yes = "${var.custom_docker_setup != "" ? 1 : 0}"
  custom_docker_setup_no  = "${var.custom_docker_setup == "" ? 1 : 0}"
}

##########################
# Logic tests for using module default systemd
##########################
locals {
  custom_systemd_yes = "${var.custom_systemd != "" ? 1 : 0}"
  custom_systemd_no  = "${var.custom_systemd == "" ? 1 : 0}"
}
