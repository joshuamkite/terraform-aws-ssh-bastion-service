############################
# User Data Templates combined
############################
data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  # systemd section
  part {
    filename     = "module_systemd"
    content_type = "text/x-shellscript"
    content      = local.custom_systemd_no ? local.systemd : "#!/bin/bash"
  }

  # ssh_populate_assume_role
  part {
    filename     = "module_ssh_populate_assume_role"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"
    content      = local.assume_role_yes * local.custom_ssh_populate_no != 0 ? local.ssh_populate_assume_role : "#!/bin/bash"
  }

  # ssh_populate_same_account
  part {
    filename     = "module_ssh_populate_same_account"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"
    content      = local.assume_role_no * local.custom_ssh_populate_no != 0 ? local.ssh_populate_same_account : "#!/bin/bash"
  }

  # docker_setup section
  part {
    filename     = "module_docker_setup"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"
    content      = local.custom_docker_setup_no ? local.docker_setup : "#!/bin/bash"
  }

  # iam-authorized-keys-command
  part {
    filename     = "module_iam-authorized-keys-command"
    content_type = "text/x-shellscript"
    merge_type   = "str(append)"
    content      = local.custom_authorized_keys_command_no ? local.iam_authorized_keys_command : "#!/bin/bash"
  }

  part {
    filename     = "extra_user_data"
    content_type = var.extra_user_data_content_type
    content      = var.extra_user_data_content != "" ? var.extra_user_data_content : "#!/bin/bash"
    merge_type   = var.extra_user_data_merge_type
  }
}

