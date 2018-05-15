#get aws region for use later in plan
data "aws_region" "current" {}

#######################
# Copy templates files to bastion host
####################

# userdata for bastion host
data "template_file" "bastion_host" {
  template = "${file("${path.module}/user_data_template/bastion_host_cloudinit_config.tpl")}"

  vars {
    bastion_host_name         = "${var.environment_name}-${data.aws_region.current.name}"
    authorized_command_code   = "${indent(8, file("${path.module}/iam_authorized_keys_code/main.go"))}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
  }
}

data "template_file" "user_data_ami_linux" {
  template = "${file("${path.module}/user_data_template/node_cloudinit_ami_linux.tpl")}"

  vars {
    bastion_host_name         = "${var.environment_name}-${data.aws_region.current.name}"
    authorized_command_code   = "${indent(8, file("${path.module}/iam_authorized_keys_code/main.go"))}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
  }
}
