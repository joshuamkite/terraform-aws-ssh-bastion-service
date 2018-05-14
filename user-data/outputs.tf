output "user_data" {
  description = "cloud-config user data used to initialize bastion at start up"
  value       = "${data.template_file.bastion_host.rendered}"
}
