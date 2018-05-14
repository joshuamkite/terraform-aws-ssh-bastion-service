output "user_data" {
  description = "cloud-config user data used to initialize bastion at start up"
  value       = "${module.bastion_user_data.user_data}"
}
