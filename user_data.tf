############################
# Templates section
############################
data "template_file" "systemd" {
  template = "${file("${path.module}/user_data/systemd.tpl")}"
  count    = "${local.custom_systemd_no}"

  vars {
    bastion_host_name = "${local.bastion_host_name}"
    vpc               = "${var.vpc}"
  }
}

data "template_file" "ssh_populate_assume_role" {
  count    = "${local.custom_ssh_populate_no}"
  template = "${file("${path.module}/user_data/ssh_populate_assume_role.tpl")}"

  vars {
    assume_role_arn = "${var.assume_role_arn}"
  }
}

data "template_file" "ssh_populate_same_account" {
  count    = "${local.custom_ssh_populate_no}"
  template = "${file("${path.module}/user_data/ssh_populate_same_account.tpl")}"
}

data "template_file" "docker_setup" {
  count    = "${local.custom_docker_setup_no}"
  template = "${file("${path.module}/user_data/docker_setup.tpl")}"

  vars {
    container_ubuntu_version = "${var.container_ubuntu_version}"
  }
}

data "template_file" "iam-authorized-keys-command" {
  count    = "${local.custom_authorized_keys_command_no}"
  template = "${file("${path.module}/user_data/iam-authorized-keys-command.tpl")}"

  vars {
    authorized_command_code   = "${file("${path.module}/user_data/iam_authorized_keys_code/main.go")}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
  }
}

############################
# Templates combined section
############################
data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  # header_all section
  part {
    filename     = "module_systemd"
    content_type = "text/x-shellscript"

    content = "${element(
    concat(data.template_file.systemd.*.rendered),
    0)}"
  }

  # ssh_populate section
  part {
    filename     = "module_ssh_populate"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"

    content = "${element(
    concat(data.template_file.ssh_populate_assume_role.*.rendered,
           data.template_file.ssh_populate_same_account.*.rendered),
    0)}"
  }

  # docker_setup section
  part {
    filename     = "module_docker_setup"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"

    content = "${element(
    concat(data.template_file.docker_setup.*.rendered),
    0)}"
  }

  # iam-authorized-keys-command
  part {
    filename     = "module_iam-authorized-keys-command"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"

    content = "${element(
    concat(data.template_file.iam-authorized-keys-command.*.rendered),
    0)}"
  }

  part {
    filename     = "extra_user_data"
    content_type = "${var.extra_user_data_content_type}"
    content      = "${var.extra_user_data_content}"
    merge_type   = "${var.extra_user_data_merge_type}"
  }
}
