############################
# Templates section
############################
data "template_file" "header_all" {
  template = "${file("${path.module}/user_data/header_all.tpl")}"

  vars {
    bastion_host_name = "${local.bastion_host_name}"
  }
}

data "template_file" "ssh_populate_assume_role" {
  count    = "${local.custom_populate_no}"
  template = "${file("${path.module}/user_data/ssh_populate_assume_role.tpl")}"

  vars {
    assume_role_arn = "${var.assume_role_arn}"
  }
}

data "template_file" "ssh_populate_same_account" {
  count    = "${local.custom_populate_no}"
  template = "${file("${path.module}/user_data/ssh_populate_same_account.tpl")}"
}

data "template_file" "dockerfile" {
  count    = "${local.custom_container_no}"
  template = "${file("${path.module}/user_data/dockerfile.tpl")}"

  vars {
    container_ubuntu_version = "${var.container_ubuntu_version}"
  }
}

data "template_file" "iam-authorized-keys-command" {
  count    = "${local.custom_authorized_keys_command_no}"
  template = "${file("${path.module}/user_data/iam-authorized-keys-command.tpl")}"

  vars {
    authorized_command_code = "${file("${path.module}/user_data/iam_authorized_keys_code/main.go")}"
  }
}

data "template_file" "build_the_things" {
  count    = "${local.custom_build_the_things_no}"
  template = "${file("${path.module}/user_data/build_the_things.tpl")}"

  vars {
    bastion_host_name         = "${local.bastion_host_name}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
    vpc                       = "${var.vpc}"
    container_build           = "${local.container_build}"
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
    filename     = "module_header"
    content_type = "text/cloud-config"
    content      = "${data.template_file.header_all.rendered}"
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

  # docker section
  part {
    filename     = "module_dockerfile"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"

    content = "${element(
    concat(data.template_file.dockerfile.*.rendered),
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

  # build_the_things section
  part {
    filename     = "module_build_the_things"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"

    content = "${element(
    concat(data.template_file.build_the_things.*.rendered,
           data.template_file.build_the_things.*.rendered),
    0)}"
  }

  part {
    filename     = "extra_user_data"
    content_type = "${var.extra_user_data_content_type}"
    content      = "${var.extra_user_data_content}"
    merge_type   = "${var.extra_user_data_merge_type}"
  }
}
