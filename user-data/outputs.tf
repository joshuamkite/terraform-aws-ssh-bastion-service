output "user_data" {
  description = "cloud-config user data used to initialize bastion at start up"
  value       = "${data.template_file.bastion_host.rendered}"
}

output "user_data_ami_linux" {
  description = "cloud-config user data used to initialize ami linux instances which are run as ecs/k8s nodes"
  value       = "${data.template_file.user_data_ami_linux.rendered}"
}
