output "instance_profile" {
  value = "${aws_iam_instance_profile.bastion_service_profile.name}"
}
