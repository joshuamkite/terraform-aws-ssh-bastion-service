############################
# Templates section
############################
data "template_file" "header_all" {
  template = "${file("${path.module}/user_data/header_all.tpl")}"
}

data "template_file" "dockerfile" {
  count    = "${local.custom_container_no}"
  template = "${file("${path.module}/user_data/dockerfile/dockerfile.tpl")}"

  vars {
    container_ubuntu_version = "${var.container_ubuntu_version}"
  }
}

data "template_file" "user_data_assume_role" {
  count    = "${local.assume_role_yes}"
  template = "${file("${path.module}/user_data/bastion_host_cloudinit_config_assume_role.tpl")}"

  vars {
    bastion_host_name         = "${local.bastion_host_name}"
    authorized_command_code   = "${indent(8, file("${path.module}/user_data/iam_authorized_keys_code/main.go"))}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
    vpc                       = "${var.vpc}"
    assume_role_arn           = "${var.assume_role_arn}"
    container_ubuntu_version  = "${var.container_ubuntu_version}"
    container_build           = "${local.container_build}"
  }
}

data "template_file" "user_data_same_account" {
  count    = "${local.assume_role_no}"
  template = "${file("${path.module}/user_data/bastion_host_cloudinit_config.tpl")}"

  vars {
    bastion_host_name         = "${local.bastion_host_name}"
    authorized_command_code   = "${indent(8, file("${path.module}/user_data/iam_authorized_keys_code/main.go"))}"
    bastion_allowed_iam_group = "${var.bastion_allowed_iam_group}"
    vpc                       = "${var.vpc}"
    container_ubuntu_version  = "${var.container_ubuntu_version}"
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

  # docker section
  part {
    filename     = "module_dockerfile"
    content_type = "text/part-handler"
    merge_type   = "str(append)"

    content = "${element(
    concat(data.template_file.dockerfile.*.rendered),
    0)}"
  }

  # main section
  part {
    filename     = "module_user_data"
    content_type = "text/part-handler"
    merge_type   = "str(append)"

    content = "${element(
    concat(data.template_file.user_data_assume_role.*.rendered,
           data.template_file.user_data_same_account.*.rendered),
    0)}"
  }

  part {
    filename     = "extra_user_data"
    content_type = "${var.extra_user_data_content_type}"
    content      = "${var.extra_user_data_content}"
    merge_type   = "${var.extra_user_data_merge_type}"
  }
}
